---
title: Prerequisites
layout: default
nav_order: 3
permalink: /prerequisites/
description: >-
  What you need before baseline relay_iport. HA extras live on those chapters.
---

<div class="conduit-hero">
  <p class="conduit-kicker">before baseline</p>
  <h1>Prerequisites</h1>
  <p class="conduit-lede">
    Only what baseline needs. Dual-AZ and multi-region list their extras on
    their own pages.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/patterns/baseline/">Start baseline</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/architecture/">Architecture</a>
  </div>
</div>

## Baseline (`relay_iport`)

| Need | Detail |
| ---- | ------ |
| VPC | Private subnet for the caster EC2 |
| NLB | Subnets in **2+ AZs** (`nlb_subnet_ids`) |
| Reach | Caster subnet can open TCP to the receiver IPort (`field_sources`) |
| Clients | CIDRs allowed on the NLB SG (`nlb_client_cidr_blocks`) |
| Auth | NTRIP client password in tfvars (not committed) |
| Access | SSM Session Manager for host logs |

## Tools

Terraform, AWS CLI v2, and the Session Manager plugin.

## Later chapters

| Chapter | Extra |
| ------- | ----- |
| [Dual-AZ]({{ site.baseurl }}/patterns/dual-az/) | Second AZ subnet · private hosted zone |
| [Multi-region]({{ site.baseurl }}/patterns/multi-region/) | SYD VPC · two profiles · zone on both VPCs |

## Read next

<div class="nav-grid">
  <a class="nav-card" href="{{ site.baseurl }}/patterns/baseline/">
    <strong>Baseline</strong>
    <span>examples/relay_iport</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/architecture/">
    <strong>Architecture</strong>
    <span>Roles and relay-pull</span>
  </a>
</div>
