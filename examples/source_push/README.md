# Source push pattern

Field device (or `ntripserver`) **uploads** to caster `:2101` (via NLB). No relay to a receiver IPort.

**Diagram:** [guide/diagrams/source-push.drawio](../../guide/diagrams/source-push.drawio)

```plaintext
Receiver / ntripserver  ─push─>  ntripcaster :2101  ←─NLB─  NTRIP clients
                                      ↑
                                 admin ALB :80  (/admin)
                                 admin ALB :9090 (Prometheus, optional)
```

## Deploy

```bash
cd examples/source_push
cp terraform.tfvars.example terraform.tfvars
# set vpc, subnet, nlb_subnet_ids, ntrip_push_password, push_sources
# optional: enable_admin_alb / enable_prometheus (+ public subnets if internet-facing)
terraform init
terraform apply
```

Prometheus is installed by userdata — after enabling it, replace the instance once:

```bash
terraform apply -replace='module.caster.aws_instance.ntripcaster'
```

Configure the device NTRIP server to:

- host = NLB DNS or caster private IP
- port = `2101`
- mount = value from `push_sources` (default `EXMP00XXX0`)
- user/pass = `ntrip_push_*` from tfvars

Extend `nlb_client_cidr_blocks` if devices push from other networks. Admin ALB
ingress is limited to `admin_cidr_blocks`. NTRIP stays on the NLB.

### DNS note (VPN)

On some corporate VPNs, `*.elb.amazonaws.com` resolves to an unreachable
`100.65.x.x` address. If the ALB hostname times out, pin public DNS (see
`examples/relay_iport/README.md`) or use `/etc/hosts`.

## Validate

```bash
terraform output admin_url
terraform output prometheus_url
curl -u "admin:$(terraform output -raw admin_password)" "$(terraform output -raw admin_url)"
```

Templates live in `../../modules/caster` — switch pattern by using `examples/relay_iport` instead.
