# Relay IPort pattern

Caster **pulls** raw RTCM from a receiver IPort (typically `:8857`). Clients **pull** NTRIP from caster `:2101` (via NLB).

**Diagram:** [guide/diagrams/relay-iport.drawio](../../guide/diagrams/relay-iport.drawio)

```plaintext
Receiver :8857  ←relay─  ntripcaster :2101  ←─NLB─  NTRIP clients
                              ↑
                         admin ALB :80  (/admin)
                         admin ALB :9090 (Prometheus, optional)
```

## Deploy

```bash
cd examples/relay_iport
cp terraform.tfvars.example terraform.tfvars
# edit vpc_id, private_subnet_id, nlb_subnet_ids, field_sources, passwords
# optional: enable_admin_alb / enable_prometheus (+ public subnets if internet-facing)
terraform init
terraform apply
```

Prometheus is installed by userdata — after enabling it, replace the instance once:

```bash
terraform apply -replace='module.caster.aws_instance.ntripcaster'
```

## Network

`private_subnet_id` must reach the receiver IPort in `field_sources`.

Admin ALB ingress is limited to `admin_cidr_blocks`. NTRIP stays on the NLB.

### DNS note (VPN)

On some corporate VPNs, `*.elb.amazonaws.com` resolves to an unreachable
`100.65.x.x` address. If the ALB hostname times out, pin public DNS:

```bash
getent hosts "$(terraform output -raw admin_alb_dns_name)"   # if 100.65.* → broken
dig +short "$(terraform output -raw admin_alb_dns_name)" @8.8.8.8
# then either:
curl --resolve "$(terraform output -raw admin_alb_dns_name):80:$(dig +short "$(terraform output -raw admin_alb_dns_name)" @8.8.8.8 | head -1)" \
  -u "admin:$(terraform output -raw admin_password)" \
  "$(terraform output -raw admin_url)"
# or add the public IPs to /etc/hosts for that hostname
```

## Validate

```bash
terraform output admin_url
terraform output prometheus_url
curl -u "admin:$(terraform output -raw admin_password)" "$(terraform output -raw admin_url)"
```

Templates live in `../../modules/caster` — switch pattern by using another example folder.
