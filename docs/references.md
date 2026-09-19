---
title: References
layout: default
nav_order: 7
permalink: /references/
description: BKG NtripCaster docs, images, and AWS links for NLB and Route53 failover.
---

<div class="conduit-hero">
  <p class="conduit-kicker">links</p>
  <h1>References</h1>
  <p class="conduit-lede">
    BKG docs, this repo’s examples, and AWS pages for NLB health and Route53
    failover.
  </p>
</div>

## NtripCaster / NTRIP

- [NTRIP overview (BKG)](https://igs.bkg.bund.de/ntrip/)
- [Ntrip documentation (PDF)](https://igs.bkg.bund.de/root_ftp/NTRIP/documentation/NtripDocumentation.pdf)
- [BKG Professional NtripCaster manual](https://igs.bkg.bund.de/root_ftp/NTRIP/documentation/ntripcaster_manual.html)

## Code in this repo

| Path | Chapter |
| ---- | ------- |
| [`examples/relay_iport`](https://github.com/jajera/aws-ntripcaster-ha-patterns/tree/main/examples/relay_iport) | Baseline |
| [`examples/relay_iport_ha`](https://github.com/jajera/aws-ntripcaster-ha-patterns/tree/main/examples/relay_iport_ha) | Dual-AZ |
| [`examples/relay_iport_ha_mr`](https://github.com/jajera/aws-ntripcaster-ha-patterns/tree/main/examples/relay_iport_ha_mr) | Multi-region |
| [`modules/caster`](https://github.com/jajera/aws-ntripcaster-ha-patterns/tree/main/modules/caster) | Shared module |
| [`modules/bnc_client`](https://github.com/jajera/aws-ntripcaster-ha-patterns/tree/main/modules/bnc_client) | Optional BNC |
| [`guide/FAILOVER.md`](https://github.com/jajera/aws-ntripcaster-ha-patterns/blob/main/guide/FAILOVER.md) | Failover detail |
| [`ARCHITECTURE.md`](https://github.com/jajera/aws-ntripcaster-ha-patterns/blob/main/ARCHITECTURE.md) | Module / ingest roles |

| Image | Why |
| ----- | --- |
| [bkg-ntripcaster-image](https://github.com/platformfuzz/bkg-ntripcaster-image) | Caster container |
| [bkg-ntrip-client-image](https://github.com/platformfuzz/bkg-ntrip-client-image) | Optional BNC client |
| [gnss-rinex-tools-image](https://github.com/platformfuzz/gnss-rinex-tools-image) | `rinex-tools check` |

## Related labs

| Resource | Why |
| -------- | --- |
| [PrivateLink vs inspected TGW](https://pl-vs-inspected-tgw.johna.kiwi/) | Same Conduit walkthrough pattern |
| [AWS Private Connectivity Patterns](https://aws-private-connectivity-patterns-walkthrough.johna.kiwi/) | Peering, PrivateLink, Lattice, TGW |
| [AWS Icons](https://aws-icons.johna.kiwi/) | Architecture Icons used in diagrams |

## AWS documentation

- [Network Load Balancer target health](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-health-checks.html)
- [Route 53 failover routing](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-failover.html)
- [Alias records and evaluate target health](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-alias-common.html)
