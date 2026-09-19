---
title: Architecture
layout: default
nav_order: 2
permalink: /architecture/
description: >-
  What BKG NtripCaster does, the baseline relay-IPort path, and why HA is an
  AWS concern rather than a caster feature.
---

<div class="conduit-hero">
  <p class="conduit-kicker">the software</p>
  <h1>Architecture</h1>
  <p class="conduit-lede">
    One process fans streams to many clients. Our field ingest is relay-pull
    from a receiver IPort. HA chapters wrap that same process — they do not
    change how the binary works.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/prerequisites/">Prerequisites</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/patterns/baseline/">Baseline pattern</a>
  </div>
</div>

## NTRIP roles

| Role | What it is | In this lab |
| ---- | ---------- | ----------- |
| **NtripSource** | GNSS stream generator | Receiver IPort (raw RTCM TCP) |
| **NtripCaster** | Fan-out server on `:2101` | BKG Professional on EC2 |
| **NtripClient** | Pulls a mount | Rover / BNC / QC tools |
| **NtripServer** | Uploads to a caster | Not used in `relay_iport` |

The caster does **not** decode RTCM and does **not** do VRS. It terminates
NTRIP and copies bytes.

## Baseline path (`relay_iport`)

This is the normal setup — one caster, one AZ.

{% include diagram.html file="diagrams/relay-iport.svg" alt="Baseline: receiver IPort to caster to NLB to clients" %}

Terraform: `examples/relay_iport` → `modules/caster`. Inventory is
`field_sources` (IP/port/mount). Passwords and VPC IDs stay in tfvars.

{: .warning }
> One host. Host or process loss = stream down until you replace it. That is
> why the next chapters exist — not because the binary grew a cluster mode.

## What HA adds next

Work through each chapter on its own — apply, understand, then destroy before
the next stack so bills and state stay clear.

| Chapter | Example | Idea |
| ------- | ------- | ---- |
| [Dual-AZ]({{ site.baseurl }}/patterns/dual-az/) | `relay_iport_ha` | Two warm casters, **one** shared NLB, same VIP |
| [Multi-region]({{ site.baseurl }}/patterns/multi-region/) | `relay_iport_ha_mr` | One caster/NLB per region, Route53 failover DNS |

Each caster still relay-pulls the IPort on its own. Clients **reconnect** after
a drain — no mid-stream handoff.

## Module layout

| Path | Role |
| ---- | ---- |
| `modules/caster` | EC2, userdata, conf templates, optional NLB |
| `modules/bnc_client` | Optional BNC + RINEX pull client (HA drills) |
| `examples/relay_iport` | Baseline |
| `examples/relay_iport_ha` | Dual-AZ |
| `examples/relay_iport_ha_mr` | Multi-region |

## Read next

<div class="nav-grid">
  <a class="nav-card" href="{{ site.baseurl }}/prerequisites/">
    <strong>Prerequisites</strong>
    <span>What you need before baseline</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/patterns/baseline/">
    <strong>Baseline</strong>
    <span>Normal relay_iport apply</span>
  </a>
</div>
