# Relay IPort HA multi-region (one instance per region)

**PRIMARY** `ap-southeast-6` (Auckland) and **SECONDARY** `ap-southeast-2`
(Sydney). One caster + internal NLB in each region. Clients dial a stable
Route53 VIP; failover is **DNS** (alias `evaluate_target_health`), not
per-region blue/green.

**Diagrams:** [steady state](../../guide/diagrams/relay-iport-ha-mr.drawio) ·
[failover](../../guide/diagrams/relay-iport-ha-mr-failover.drawio) ·
[FAILOVER.md](../../guide/FAILOVER.md)

```plaintext
NTRIP clients  →  Route53 VIP FQDN :2101
                    ├─ PRIMARY alias  → NLB AKL → caster AKL
                    └─ SECONDARY alias → NLB SYD → caster SYD
Both casters ──relay pull──→ Receiver IPort
```

When PRIMARY’s NLB has no healthy targets, Route53 serves SECONDARY. Clients
must **reconnect** (and may need a fresh DNS lookup). Expect a **longer** gap
than dual-AZ L4 HA (~20–40s) — often **1–3+ minutes** with resolver cache.

Keep the regional NLB: the delay is mostly DNS, and the NLB gives a stable
alias target + `evaluate_target_health`. See [FAILOVER.md](../../guide/FAILOVER.md).

For AZ-level HA inside one region, use [`examples/relay_iport_ha`](../relay_iport_ha/).

## Prerequisites

1. Opt in to `ap-southeast-6` in the Auckland account.
2. Auckland VPC: private subnet for the caster + NLB subnets in **2+ AZs**.
3. Private hosted zone in the **Sydney** account, associated with **both** VPCs
   (cross-account association if needed).
4. Receiver IPort reachable from **both** regions.
5. Two AWS profiles: `primary_aws_profile` (AKL) and `secondary_aws_profile` (SYD).
6. Casters default to `m6i.large` (`ap-southeast-6` has no `m6a`).

## Deploy

```bash
cd examples/relay_iport_ha_mr
cp terraform.tfvars.example terraform.tfvars
# fill primary_aws_profile / secondary_aws_profile, VPC+subnets, zone, inventory
aws sso login --profile <akl-profile>
aws sso login --profile <syd-profile>
terraform init
terraform apply
```

VIP DNS is managed with the **secondary** profile (zone owner). Casters/NLBs use
their regional profiles; PRIMARY NLB alias may be cross-account.

Point clients at:

```bash
terraform output -raw ntrip_vip_fqdn
# dial <fqdn>:2101
```

Both casters set `caster_server_name` to that VIP.

## Drain / restore a region

```bash
./scripts/failover.sh status
./scripts/failover.sh drain-primary    # stop AKL caster → DNS should prefer SYD
./scripts/failover.sh restore-primary
./scripts/failover.sh drain-secondary
./scripts/failover.sh restore-secondary
```

Requires AWS CLI credentials and SSM in both regions.

## BNC test client

With `enable_client = true`, a BNC EC2 in the **primary** region pulls the VIP
(same pattern as single-region HA). Bootstrap also pulls
[gnss-rinex-tools-image](https://github.com/platformfuzz/gnss-rinex-tools-image)
for RINEX 3 QC (`rinex-tools check`). See [`modules/bnc_client`](../../modules/bnc_client/).

BNC writes RINEX 3 observation files every 15 minutes at 1 Hz under `/opt/bnc/rnx`.

```bash
aws ssm start-session --profile "$(terraform output -raw primary_aws_profile)" \
  --region "$(terraform output -raw primary_region)" \
  --target "$(terraform output -raw bnc_client_instance_id)"

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

## Validate

```bash
terraform output ntrip_vip_fqdn
./scripts/failover.sh status
```

Templates live in `../../modules/caster`. Dual-AZ single-region:
[`examples/relay_iport_ha`](../relay_iport_ha/).
