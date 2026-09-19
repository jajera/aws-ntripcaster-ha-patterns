---
title: Compare
layout: default
nav_order: 5
permalink: /compare/
description: >-
  After running each chapter: baseline vs dual-AZ L4 vs multi-region DNS —
  gaps and when each wins.
---

<div class="conduit-hero">
  <p class="conduit-kicker">after each chapter</p>
  <h1>Compare</h1>
  <p class="conduit-lede">
    You started with a normal single caster, then bolted on AZ HA, then region
    HA. The software never became a cluster — only the recovery plane changed.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/patterns/multi-region/#teardown">Teardown multi-region</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/patterns/multi-region/">Back: Multi-region</a>
  </div>
</div>

## Progression

| Chapter | Example | Failure you absorb | Typical gap |
| ------- | ------- | ------------------ | ----------- |
| [Baseline]({{ site.baseurl }}/patterns/baseline/) | `relay_iport` | None — host down = stream down | until you repair |
| [Dual-AZ]({{ site.baseurl }}/patterns/dual-az/) | `relay_iport_ha` | AZ / single host | **~20–40s** (~34s measured) |
| [Multi-region]({{ site.baseurl }}/patterns/multi-region/) | `relay_iport_ha_mr` | Region | **1–3+ min** (DNS) |

{% include diagram.html file="diagrams/overview.svg" alt="Dual-AZ L4 versus multi-region DNS" %}

## Dual-AZ vs multi-region

| | Dual-AZ L4 | Multi-region DNS |
| --- | --- | --- |
| Mechanism | Shared NLB target health | Route53 failover aliases |
| VIP on failover | **Unchanged** | Same FQDN, **new answer** |
| Dominant delay | NLB unhealthy + reconnect | Resolver / TTL |
| Keep NLB? | Yes (the failover plane) | Yes (stable alias + health) |

{: .finding }
> Dual-AZ wins on **recovery time**. Multi-region wins on **regional blast
> radius**. Neither migrates an established TCP stream — NtripCaster never
> did that.

## Decision

| Choose | When |
| ------ | ---- |
| **Baseline only** | Lab / single site; accept host repair time |
| **Dual-AZ** | AZ / host resilience; shortest reconnect gap |
| **Multi-region** | Region diversity; accept minute-scale DNS |
| **Neither HA alone** | Continuous fixed / safety-critical without a hotter path |

**Normal setup → prove the stream → dual-AZ if you need AZ HA → multi-region
if you need regional diversity.**

## Read next

<div class="nav-grid">
  <a class="nav-card" href="{{ site.baseurl }}/teardown/">
    <strong>Teardown index</strong>
    <span>Links into each chapter’s Teardown</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/patterns/baseline/">
    <strong>Baseline</strong>
    <span>Re-run normal setup</span>
  </a>
</div>
