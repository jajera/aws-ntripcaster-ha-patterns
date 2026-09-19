# aws-ntripcaster-ha-patterns

BKG Professional NtripCaster on AWS: start from a **normal** relay-IPort
deploy, then add dual-AZ L4 and multi-region DNS HA — **one example at a
time**. The caster isn’t designed for HA; we make it work with AWS around it.

```text
.
├── modules/caster · modules/bnc_client
├── examples/
│   ├── relay_iport/         # baseline (normal setup)
│   ├── relay_iport_ha/      # dual-AZ shared NLB
│   ├── relay_iport_ha_mr/   # multi-region DNS
│   └── source_push/         # alternate ingest (not in walkthrough)
├── guide/                   # FAILOVER, PATTERNS, draw.io
├── ARCHITECTURE.md
├── docs/                    # walkthrough site (Jekyll)
└── scripts/
```

## Walkthrough

| Page | Purpose |
| ---- | ------- |
| [Overview](docs/index.md) | Software story + chapter order |
| [Architecture](docs/architecture.md) | Roles, baseline path, why HA is bolted on |
| [Prerequisites](docs/prerequisites.md) | What baseline needs |
| [Patterns · Baseline](docs/patterns/baseline.md) | `relay_iport` |
| [Patterns · Dual-AZ](docs/patterns/dual-az.md) | `relay_iport_ha` |
| [Patterns · Multi-region](docs/patterns/multi-region.md) | `relay_iport_ha_mr` |
| [Compare](docs/compare.md) | After each chapter |
| [Teardown](docs/teardown.md) | Destroy the chapter you applied |

Published: `https://aws-ntripcaster-ha-patterns.johna.kiwi/`

```bash
./scripts/docs-serve.sh   # http://127.0.0.1:4000/
```

## Deploy (Terraform)

```bash
cd examples/relay_iport          # start here
# later: relay_iport_ha · relay_iport_ha_mr
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

See [guide/FAILOVER.md](guide/FAILOVER.md) and [ARCHITECTURE.md](ARCHITECTURE.md).

## License

MIT — see [LICENSE](LICENSE).
