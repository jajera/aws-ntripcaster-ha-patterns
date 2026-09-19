---
title: Multi-region
layout: default
parent: Patterns
nav_order: 3
permalink: /patterns/multi-region/
description: >-
  PRIMARY Auckland and SECONDARY Sydney with Route53 failover DNS.
---

<div class="conduit-hero">
  <p class="conduit-kicker">patterns / 3 · after dual-AZ</p>
  <h1>Multi-region</h1>
  <p class="conduit-lede">
    One caster + NLB per region. Failover is DNS — keep the regional NLBs.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/compare/">Next: Compare</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/patterns/dual-az/">Back: Dual-AZ</a>
  </div>
</div>

{% include diagram.html file="diagrams/multi-region.svg" alt="Multi-region steady state" %}

{: .cost }
> <code>examples/relay_iport_ha_mr</code> — own state. Destroy dual-AZ first.

## Deploy

| Need | Detail |
| ---- | ------ |
| Regions | AKL (`ap-southeast-6`) + SYD (`ap-southeast-2`) |
| Zone | On **both** VPCs (often SYD-owned) |
| Profiles | `primary_aws_profile` + `secondary_aws_profile` |
| IPort | Reachable from both regions |

```bash
aws sso login --profile <akl-profile>
aws sso login --profile <syd-profile>
cd examples/relay_iport_ha_mr
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output -raw ntrip_vip_fqdn   # dial :2101
```

## Explain

{% include diagram.html file="diagrams/multi-region-failover.svg" alt="Multi-region drain PRIMARY" %}

Route53 failover aliases (`evaluate_target_health`). Delay is mostly DNS TTL —
not “missing” an NLB.

```bash
cd examples/relay_iport_ha_mr
./scripts/failover.sh status
./scripts/failover.sh drain-primary
./scripts/failover.sh restore-primary
```

{: .finding }
> **1–3+ minutes** typical. Longer than dual-AZ because of DNS.

## Teardown

```bash
cd examples/relay_iport_ha_mr
aws sso login --profile <akl-profile>
aws sso login --profile <syd-profile>
terraform destroy
```

## Read next

<div class="nav-grid">
  <a class="nav-card" href="{{ site.baseurl }}/compare/">
    <strong>Compare</strong>
    <span>Gaps and when each wins</span>
  </a>
</div>
