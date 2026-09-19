#!/usr/bin/env bash
# Drain or restore a regional caster (multi-region PRIMARY/SECONDARY VIP).
#
# Failover between regions is Route53 alias health (PRIMARY → SECONDARY), not
# L4 blue/green. Drain primary (stop ntripcaster) to force DNS to secondary.
#
# Usage (from examples/relay_iport_ha_mr after apply):
#   ./scripts/failover.sh status
#   ./scripts/failover.sh drain-primary|restore-primary
#   ./scripts/failover.sh drain-secondary|restore-secondary
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

cmd="${1:-status}"

primary_id="$(terraform output -raw primary_instance_id)"
secondary_id="$(terraform output -raw secondary_instance_id)"
primary_region="$(terraform output -raw primary_region)"
secondary_region="$(terraform output -raw secondary_region)"
primary_profile="$(terraform output -raw primary_aws_profile)"
secondary_profile="$(terraform output -raw secondary_aws_profile)"
vip="$(terraform output -raw ntrip_vip_fqdn)"
primary_tg="$(terraform output -raw primary_nlb_target_group_arn)"
secondary_tg="$(terraform output -raw secondary_nlb_target_group_arn)"

ssm_run() {
  local instance_id="$1"
  local region="$2"
  local profile="$3"
  local remote_cmd="$4"
  local cid
  cid="$(aws --profile "$profile" ssm send-command \
    --region "$region" \
    --instance-ids "$instance_id" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[\"${remote_cmd}\"]" \
    --query 'Command.CommandId' \
    --output text)"
  echo "SSM command ${cid} on ${instance_id} (${region} profile=${profile})..."
  aws --profile "$profile" ssm wait command-executed --region "$region" --command-id "$cid" --instance-id "$instance_id" || true
  aws --profile "$profile" ssm get-command-invocation \
    --region "$region" \
    --command-id "$cid" \
    --instance-id "$instance_id" \
    --query '{Status:Status,Stdout:StandardOutputContent,Stderr:StandardErrorContent}' \
    --output json
}

tg_health() {
  local label="$1"
  local region="$2"
  local profile="$3"
  local tg="$4"
  echo "=== ${label} TG (${region} profile=${profile}) ==="
  aws --profile "$profile" elbv2 describe-target-health \
    --region "$region" \
    --target-group-arn "$tg" \
    --query 'TargetHealthDescriptions[].{Id:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason}' \
    --output table
}

case "$cmd" in
  status)
    echo "VIP: ${vip}:2101 (PRIMARY=${primary_region}/${primary_profile} SECONDARY=${secondary_region}/${secondary_profile})"
    echo "Primary instance:   ${primary_id}"
    echo "Secondary instance: ${secondary_id}"
    tg_health "primary" "$primary_region" "$primary_profile" "$primary_tg"
    tg_health "secondary" "$secondary_region" "$secondary_profile" "$secondary_tg"
    ;;
  drain-primary)
    echo "Stopping ntripcaster on primary ${primary_id} (${primary_region})..."
    ssm_run "$primary_id" "$primary_region" "$primary_profile" "systemctl stop ntripcaster.service; echo stopped"
    echo "Wait for NLB unhealthy + Route53 to prefer SECONDARY (often 1–3+ min with DNS cache)..."
    sleep 30
    tg_health "primary" "$primary_region" "$primary_profile" "$primary_tg"
    tg_health "secondary" "$secondary_region" "$secondary_profile" "$secondary_tg"
    echo "New resolves of ${vip} should prefer secondary when primary TG is unhealthy."
    ;;
  restore-primary)
    echo "Starting ntripcaster on primary ${primary_id} (${primary_region})..."
    ssm_run "$primary_id" "$primary_region" "$primary_profile" "systemctl start ntripcaster.service; sleep 2; systemctl is-active ntripcaster.service"
    echo "Wait for NLB healthy + Route53 PRIMARY..."
    sleep 30
    tg_health "primary" "$primary_region" "$primary_profile" "$primary_tg"
    ;;
  drain-secondary)
    echo "Stopping ntripcaster on secondary ${secondary_id} (${secondary_region})..."
    ssm_run "$secondary_id" "$secondary_region" "$secondary_profile" "systemctl stop ntripcaster.service; echo stopped"
    sleep 30
    tg_health "secondary" "$secondary_region" "$secondary_profile" "$secondary_tg"
    ;;
  restore-secondary)
    echo "Starting ntripcaster on secondary ${secondary_id} (${secondary_region})..."
    ssm_run "$secondary_id" "$secondary_region" "$secondary_profile" "systemctl start ntripcaster.service; sleep 2; systemctl is-active ntripcaster.service"
    sleep 30
    tg_health "secondary" "$secondary_region" "$secondary_profile" "$secondary_tg"
    ;;
  *)
    echo "Usage: $0 {status|drain-primary|restore-primary|drain-secondary|restore-secondary}" >&2
    exit 1
    ;;
esac
