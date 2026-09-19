# Relay IPort HA (single-region blue/green)

**One region, two AZs.** Two warm casters share **one** internal NLB. Clients
dial a stable Route53 alias to that NLB. Failover is L4 target health (~20s),
not DNS PRIMARY/SECONDARY.

**Diagrams:** [steady state](../../guide/diagrams/relay-iport-ha.drawio) ·
[failover](../../guide/diagrams/relay-iport-ha-failover.drawio) ·
[FAILOVER.md](../../guide/FAILOVER.md)

```plaintext
NTRIP clients  →  Route53 VIP FQDN :2101  →  shared NLB
                                              ├─ blue caster  (AZ-a)
                                              └─ green caster (AZ-b)
Both casters ──relay pull──→ Receiver IPort
```

When both are healthy, new connections can land on either side (source-IP
stickiness). A dead node is removed from the TG; clients must **reconnect** to
the same VIP (in-flight TCP on the failed node drops). This is not multi-region
or zero-disconnect stream HA.

**Expected outage on drain:** ~20–40s of missing epochs on a reconnecting client
(NLB unhealthy ~20s + client reconnect). Measured with the optional BNC client:
about **34s** of 1 Hz RINEX gap during a green→blue drill. Fine for
post-processed RINEX / QC; RTK will notice a short drop.

## Deploy

```bash
cd examples/relay_iport_ha
cp terraform.tfvars.example terraform.tfvars
# fill vpc_id, blue/green subnets (different AZs, same region), nlb_subnet_ids,
# route53_zone_id (private zone on the VPC), field_sources, passwords
terraform init
terraform apply
```

Point clients at:

```bash
terraform output -raw ntrip_vip_fqdn
# dial <fqdn>:2101
```

Both casters set `caster_server_name` to that VIP so sourcetable CAS matches.

## How failover works

Full write-up: [guide/FAILOVER.md](../../guide/FAILOVER.md).

1. One NLB, one TG, both instances attached; TCP health on `:2101` (interval 10s,
   unhealthy threshold 2 → ~20s).
2. Route53 is a **simple alias** to the NLB (stable name). VIP does not change
   on failover.
3. Stop or lose blue → NLB sends new connections to green only (same FQDN).

Admin UI: SSM to whichever side you need (no dual admin ALB in this example).

## Drain / restore a side

```bash
./scripts/failover.sh status       # TG health for blue + green
./scripts/failover.sh drain-blue   # stop ntripcaster on blue
./scripts/failover.sh restore-blue # start ntripcaster on blue
./scripts/failover.sh drain-green
./scripts/failover.sh restore-green
```

Requires AWS CLI credentials and SSM access to the instances. After a drain,
wait ~25s then confirm the drained target is `unhealthy` and the other side
`healthy`.

## BNC test client

With `enable_client = true`, a standalone [`modules/bnc_client`](../../modules/bnc_client/)
EC2 (not part of blue/green) runs
[bkg-ntrip-client-image](https://github.com/platformfuzz/bkg-ntrip-client-image)
from GHCR and pulls `ntrip_vip_fqdn` / the first mount. Bootstrap also pulls
[gnss-rinex-tools-image](https://github.com/platformfuzz/gnss-rinex-tools-image)
for RINEX 3 QC (`rinex-tools check`).

BNC writes RINEX 3 observation files every 15 minutes at 1 Hz under `/opt/bnc/rnx`.

```bash
terraform output -raw bnc_client_instance_id
aws ssm start-session --target "$(terraform output -raw bnc_client_instance_id)"

# on the instance:
sudo docker inspect bnc-client --format 'health={{.State.Health.Status}}'
ls -la /opt/bnc/logs /opt/bnc/rnx

# RINEX structure check (after ~15 min of data):
sudo docker run --rm -v /opt/bnc/rnx:/data:ro \
  ghcr.io/platformfuzz/gnss-rinex-tools-image:latest \
  check /data/<file.rnx>
```

`rinex-tools check` validates RINEX 3 structure; it does **not** report time
gaps. To measure failover impact, scan epoch timestamps in the 15‑minute file
that covers the drain (look for jumps over 1–2 s at 1 Hz).

## Network

- `blue_private_subnet_id` and `green_private_subnet_id` must both reach the
  receiver IPort addresses in `field_sources` (same region, different AZs).
- Use a **private** hosted zone associated with the VPC so the VIP resolves to
  the internal NLB inside the VPC.
- `nlb_client_cidr_blocks` must include real client source CIDRs (instance-target
  NLB preserves client IP).

## Validate

```bash
terraform output ntrip_vip_fqdn
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw nlb_target_group_arn)"
./scripts/failover.sh status
```

Templates live in `../../modules/caster`. Single-node pattern:
[`examples/relay_iport`](../relay_iport/).
