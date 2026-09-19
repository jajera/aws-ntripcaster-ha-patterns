# Architecture diagrams

Official AWS-style draw.io diagrams for each ingest pattern. Open in
[diagrams.net](https://app.diagrams.net/) (File → Open from → Device) or VS Code
Draw.io extension.

| Diagram | Pattern | Description |
| ------- | ------- | ----------- |
| [relay-iport.drawio](relay-iport.drawio) | `examples/relay_iport` | Caster relay-pulls receiver IPort; clients via NLB |
| [source-push.drawio](source-push.drawio) | `examples/source_push` | Field NtripServer push + client pull on NLB |
| [relay-iport-ha.drawio](relay-iport-ha.drawio) | `examples/relay_iport_ha` | Blue/green, shared NLB, Route 53 alias VIP |
| [relay-iport-ha-failover.drawio](relay-iport-ha-failover.drawio) | HA failover | Drain one side; same VIP; ~20–40s client gap |
| [relay-iport-ha-mr.drawio](relay-iport-ha-mr.drawio) | `examples/relay_iport_ha_mr` | AKL PRIMARY + SYD SECONDARY, one caster/NLB each |
| [relay-iport-ha-mr-failover.drawio](relay-iport-ha-mr-failover.drawio) | MR failover | Drain primary; DNS to secondary |

Failover write-up: [FAILOVER.md](../FAILOVER.md). Pattern notes: [PATTERNS.md](../PATTERNS.md).
