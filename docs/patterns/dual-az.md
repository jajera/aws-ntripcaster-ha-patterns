---
title: Dual-AZ
layout: default
parent: Patterns
nav_order: 2
permalink: /patterns/dual-az/
description: >-
  Two warm casters behind one shared NLB and a stable Route53 VIP.
---

<div class="conduit-hero">
  <p class="conduit-kicker">patterns / 2 · after baseline</p>
  <h1>Dual-AZ</h1>
  <p class="conduit-lede">
    Two casters, different AZs, one shared NLB. Failover is L4 health — not a
    clustered caster.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/patterns/multi-region/">Next: Multi-region</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/patterns/baseline/">Back: Baseline</a>
  </div>
</div>

{% include diagram.html file="diagrams/dual-az.svg" alt="Dual-AZ steady state" %}

{: .cost }
> <code>examples/relay_iport_ha</code> — own state. Destroy baseline first.

## Deploy

| Need | Detail |
| ---- | ------ |
| Two AZs | `blue_private_subnet_id` + `green_private_subnet_id` |
| NLB | Subnets in 2+ AZs |
| Zone | `route53_zone_id` on the VPC |

```bash
cd examples/relay_iport_ha
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output -raw ntrip_vip_fqdn   # dial :2101
```

## Explain

{% include diagram.html file="diagrams/dual-az-failover.svg" alt="Dual-AZ drain green" %}

L4 target health on `:2101` (~20s unhealthy). VIP stays put; drained TCP still
drops — clients reconnect.

```bash
cd examples/relay_iport_ha
./scripts/failover.sh status
./scripts/failover.sh drain-green    # wait ~25s
./scripts/failover.sh restore-green
```

{: .finding }
> **~20–40s** gap (~34s measured). VIP does not change.

## Teardown

```bash
cd examples/relay_iport_ha && terraform destroy
```

## Read next

<div class="nav-grid">
  <a class="nav-card" href="{{ site.baseurl }}/patterns/multi-region/">
    <strong>Multi-region</strong>
    <span>DNS failover</span>
  </a>
</div>
