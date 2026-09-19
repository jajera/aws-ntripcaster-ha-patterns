---
title: Overview
layout: default
nav_order: 1
description: >-
  BKG Professional NtripCaster on AWS — start from a normal relay-IPort
  setup, then harden for dual-AZ and multi-region HA.
---

<div class="conduit-hero">
  <p class="conduit-kicker">jajera / aws-ntripcaster-ha-patterns</p>
  <h1>NTRIP caster HA patterns</h1>
  <p class="conduit-lede">
    BKG’s Professional NtripCaster fans GNSS streams — it does not fail over.
    This walkthrough keeps it reachable with AWS around it, one pattern at a
    time.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/patterns/baseline/">Start with baseline</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/architecture/">What is NtripCaster?</a>
  </div>
</div>

## The idea

**NTRIP** carries GNSS corrections over IP. A **NtripCaster** sits in the
middle on TCP **2101**. This lab runs
**[BKG Professional](https://igs.bkg.bund.de/ntrip/)** on EC2 and
**relay-pulls** raw RTCM from a receiver IPort.

It is not clustered, not connection-migrating, and not VRS. When a host dies,
in-flight TCP **drops** — clients reconnect. HA is AWS around that process.

{% include diagram.html file="diagrams/overview.svg" alt="Dual-AZ shared NLB versus multi-region Route53 failover" %}

{: .note }
> Focus is caster reachability. User management / admin sync are out of scope.

## Read next

<div class="nav-grid">
  <a class="nav-card" href="{{ site.baseurl }}/architecture/">
    <strong>1. Architecture</strong>
    <span>Roles, relay-pull, why HA is bolted on</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/prerequisites/">
    <strong>2. Prerequisites</strong>
    <span>VPC, zone, tools</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/patterns/baseline/">
    <strong>3. Baseline</strong>
    <span>Normal relay_iport deploy</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/patterns/dual-az/">
    <strong>4. Dual-AZ</strong>
    <span>After baseline works</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/patterns/multi-region/">
    <strong>5. Multi-region</strong>
    <span>After dual-AZ</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/compare/">
    <strong>6. Compare</strong>
    <span>Gaps and when each wins</span>
  </a>
</div>
