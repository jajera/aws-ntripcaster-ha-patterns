# Ingest patterns

Examples share `modules/caster`. The example folder sets `ingest_pattern` and the
matching inventory variables. Architecture diagrams:
[guide/diagrams/](diagrams/).

## `relay_iport` → `examples/relay_iport`

[Diagram](diagrams/relay-iport.drawio)

```plaintext
Receiver IPort :8857  ←TCP─  caster (relay pull)  ─NTRIP─>  clients :2101
```

| tfvars | Role |
| -------- | ------ |
| `field_sources` | IP/port/mount/STR — becomes `relay pull` lines |
| `ntrip_client_*` | Client pull auth |
| `push_sources` | unused (leave empty) |

**Network:** caster subnet must reach each receiver IPort address.

## `relay_iport` HA → `examples/relay_iport_ha` (single region)

[Steady state](diagrams/relay-iport-ha.drawio) ·
[Failover](diagrams/relay-iport-ha-failover.drawio) ·
[FAILOVER.md](FAILOVER.md)

```plaintext
Receiver IPort  ←TCP─  blue + green casters  ←─ shared NLB  ←─ Route53 alias VIP
NTRIP clients dial VIP FQDN :2101 (same region, two AZs; L4 health failover)
```

Same `field_sources` / `ntrip_client_*` as single-node. Requires a private hosted
zone (`route53_zone_id`), blue/green private subnets (different AZs, **same
region**), and NLB subnets. Failover is NLB target health (~20s), not Route53
failover routing — clients must reconnect; expect ~20–40s of missing stream
data on drain. Optional `modules/bnc_client` pulls the VIP for RINEX drills.
Drain/restore: `scripts/failover.sh`.

## `relay_iport` HA multi-region → `examples/relay_iport_ha_mr`

[Steady state](diagrams/relay-iport-ha-mr.drawio) ·
[Failover](diagrams/relay-iport-ha-mr-failover.drawio) ·
[FAILOVER.md](FAILOVER.md)

```plaintext
Receiver IPort  ←TCP─  caster AKL + caster SYD
NTRIP clients ──► Route53 VIP ──PRIMARY──► NLB AKL
                              ──SECONDARY─► NLB SYD
```

One instance + NLB per region (`ap-southeast-6` PRIMARY, `ap-southeast-2`
SECONDARY). Dual AWS profiles/accounts supported; VIP DNS is owned by the
Sydney account. Same `field_sources` / `ntrip_client_*`. Private zone must be
associated with **both** VPCs. Failover is Route53 alias health (DNS) — expect
**1–3+ minutes** gaps (keep regional NLBs; delay is mostly DNS cache). Default
caster type `m6i.large` (no `m6a` in NZ). Optional BNC in primary +
`rinex-tools check`. Drain/restore: `scripts/failover.sh`. AWS provider
`>= 6.13.0`. Details: [FAILOVER.md](FAILOVER.md).

## `source_push` → `examples/source_push`

[Diagram](diagrams/source-push.drawio)

```plaintext
Receiver / ntripserver  ─NTRIP push─>  caster :2101  ─NTRIP─>  clients
```

| tfvars | Role |
| -------- | ------ |
| `push_sources` | mount/STR — sourcemounts + sourcetable |
| `ntrip_push_*` | source upload auth |
| `ntrip_client_*` | client pull auth |
| `field_sources` | unused |

No `relay` lines. Device must reach caster/NLB `:2101`.

## Reuse

To add another pattern: new `examples/<name>/` that sets `ingest_pattern`
(extend module validation) and passes the matching inventory. Keep templates in
the module; add a draw.io under `guide/diagrams/`.
