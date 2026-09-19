---
title: Teardown
layout: default
nav_order: 6
permalink: /teardown/
description: >-
  Each pattern chapter has its own Teardown. Use that page for the folder you
  applied.
---

<div class="conduit-hero">
  <p class="conduit-kicker">after the chapter</p>
  <h1>Teardown</h1>
  <p class="conduit-lede">
    Destroy lives with the chapter that created the stack — so cost and
    conflicts stay obvious. Jump to the Teardown section for the example you
    still have up.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/patterns/">Patterns</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/compare/">Compare</a>
  </div>
</div>

{: .warning }
> Destroy deletes casters, NLBs, and VIP records for that example. Leave field
> VPCs, subnets, and the private hosted zone alone.

## Per chapter

| If you applied | Teardown on |
| -------------- | ----------- |
| Baseline | [Patterns · Baseline → Teardown]({{ site.baseurl }}/patterns/baseline/#teardown) |
| Dual-AZ | [Patterns · Dual-AZ → Teardown]({{ site.baseurl }}/patterns/dual-az/#teardown) |
| Multi-region | [Patterns · Multi-region → Teardown]({{ site.baseurl }}/patterns/multi-region/#teardown) |

If more than one is still live, destroy multi-region first, then dual-AZ, then
baseline — or any order if they do not share resources.

## Read next

<div class="nav-grid">
  <a class="nav-card" href="{{ site.baseurl }}/compare/">
    <strong>Compare</strong>
    <span>Gaps and decision</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/references/">
    <strong>References</strong>
    <span>BKG docs and AWS links</span>
  </a>
</div>
