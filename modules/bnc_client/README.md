# BNC client module

Standalone EC2 that runs [BKG Ntrip Client](https://github.com/platformfuzz/bkg-ntrip-client-image)
in Docker and pulls an NTRIP caster (VIP or host). Used by
[`examples/relay_iport_ha`](../../examples/relay_iport_ha/) for failover drills;
not part of blue/green caster capacity.

## What it does

1. Installs Docker on Amazon Linux 2023.
2. Pulls `bnc_image`, seeds `bnc.conf` with `autoStart=1`, mount, and RINEX 3
   paths (`rnxIntr=15 min`, `rnxSampl=1 sec`, `rnxVersion=3`).
3. Runs BNC with `--entrypoint /opt/bnc/BNC -nw` (batch / no GUI).
4. Pulls `rinex_tools_image` for optional QC:

```bash
sudo docker run --rm -v /opt/bnc/rnx:/data:ro \
  ghcr.io/platformfuzz/gnss-rinex-tools-image:latest \
  check /data/<file.rnx>
```

`check` validates RINEX 3 **structure** only (not epoch time gaps).

Host paths: `/opt/bnc/logs`, `/opt/bnc/rnx`, `/opt/bnc/conf/bnc.conf`.

## Usage

```hcl
module "bnc_client" {
  source = "../../modules/bnc_client"

  vpc_id      = var.vpc_id
  subnet_id   = var.private_subnet_id
  name_prefix = "ntrip-bnc"

  caster_host = "ntrip.example.internal"
  mountpoint  = "AVLN00NZL0"

  ntrip_username = var.ntrip_client_username
  ntrip_password = var.ntrip_client_password
}
```

Defaults pull public GHCR images. Override `bnc_image` /
`rinex_tools_image` if you pin digests.

## Notes

- Subnet needs VPC DNS (for VIP) and egress to GHCR + the caster.
- Instance has SSM; prefer Session Manager over SSH.
- Changing userdata replaces the instance (`user_data_replace_on_change`).
