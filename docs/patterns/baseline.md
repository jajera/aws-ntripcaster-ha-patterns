---
title: Baseline
layout: default
parent: Patterns
nav_order: 1
permalink: /patterns/baseline/
description: >-
  Single-caster relay_iport — prove the stream before HA.
---

<div class="conduit-hero">
  <p class="conduit-kicker">patterns / 1 · normal setup</p>
  <h1>Baseline</h1>
  <p class="conduit-lede">
    One EC2, relay-pull from the IPort, clients on the NLB. Prove it streams
    before you add HA.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/patterns/dual-az/">Next: Dual-AZ</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/patterns/">Patterns</a>
  </div>
</div>

{% include diagram.html file="diagrams/relay-iport.svg" alt="Baseline relay IPort path" %}

{: .cost }
> Destroy this stack before dual-AZ — separate state, double the bill if both
> stay up.

## Deploy

```bash
cd examples/relay_iport
cp terraform.tfvars.example terraform.tfvars
# vpc_id, private_subnet_id, nlb_subnet_ids, field_sources, passwords
terraform init && terraform apply
terraform output   # dial NLB :2101
```

{: .tip }
> If clients never get a mount, stop here. HA will not fix a bad baseline.

## Explain

Same `modules/caster` the HA chapters reuse. One process — host loss means the
stream is down until you replace it.

## Teardown

```bash
cd examples/relay_iport && terraform destroy
```

Leave field VPCs and hosted zones alone.

## Read next

<div class="nav-grid">
  <a class="nav-card" href="{{ site.baseurl }}/patterns/dual-az/">
    <strong>Dual-AZ</strong>
    <span>Shared NLB HA</span>
  </a>
</div>
