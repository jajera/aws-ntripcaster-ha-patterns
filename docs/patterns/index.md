---
title: Patterns
layout: default
nav_order: 4
has_children: true
permalink: /patterns/
description: >-
  One example at a time: baseline, dual-AZ, then multi-region.
---

<div class="conduit-hero">
  <p class="conduit-kicker">one example at a time</p>
  <h1>Patterns</h1>
  <p class="conduit-lede">
    Three folders. Apply one, understand it, destroy it, then move on.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/patterns/baseline/">1 · Baseline</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/prerequisites/">Prerequisites</a>
  </div>
</div>

{% include diagram.html file="diagrams/overview.svg" alt="Dual-AZ L4 versus multi-region DNS" %}

{: .cost }
> EC2 + NLB bill while a stack is up. Tear down that folder only — leave field
> VPCs and hosted zones alone.

## Chapters

<div class="path-grid">
  <a class="path-card" href="{{ site.baseurl }}/patterns/baseline/">
    <span class="path-card__label">1</span>
    <strong>Baseline</strong>
    <span class="path-card__meta"><code>relay_iport</code></span>
  </a>
  <a class="path-card" href="{{ site.baseurl }}/patterns/dual-az/">
    <span class="path-card__label">2</span>
    <strong>Dual-AZ</strong>
    <span class="path-card__meta"><code>relay_iport_ha</code></span>
  </a>
  <a class="path-card" href="{{ site.baseurl }}/patterns/multi-region/">
    <span class="path-card__label">3</span>
    <strong>Multi-region</strong>
    <span class="path-card__meta"><code>relay_iport_ha_mr</code></span>
  </a>
</div>
