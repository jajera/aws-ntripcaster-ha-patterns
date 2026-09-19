#!/usr/bin/env bash
# Drain or restore a blue/green caster behind the shared NLB (same VIP FQDN).
#
# NLB TCP health: interval 10s, unhealthy_threshold 2 → ~20s before new
# connections skip a drained node. Reconnecting clients typically see ~20–40s
# of missing stream data (not zero-disconnect HA).
#
# Usage (from examples/relay_iport_ha after apply):
#   ./scripts/failover.sh status
#   ./scripts/failover.sh drain-blue|restore-blue
#   ./scripts/failover.sh drain-green|restore-green
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

cmd="${1:-status}"

blue_id="$(terraform output -raw blue_instance_id)"
green_id="$(terraform output -raw green_instance_id)"
vip="$(terraform output -raw ntrip_vip_fqdn)"
tg="$(terraform output -raw nlb_target_group_arn)"

ssm_run() {
  local instance_id="$1"
  local remote_cmd="$2"
  local cid
  cid="$(aws ssm send-command \
    --instance-ids "$instance_id" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[\"${remote_cmd}\"]" \
    --query 'Command.CommandId' \
    --output text)"
  echo "SSM command ${cid} on ${instance_id}..."
  aws ssm wait command-executed --command-id "$cid" --instance-id "$instance_id" || true
  aws ssm get-command-invocation \
    --command-id "$cid" \
    --instance-id "$instance_id" \
    --query '{Status:Status,Stdout:StandardOutputContent,Stderr:StandardErrorContent}' \
    --output json
}

tg_health() {
  echo "=== shared TG ==="
  aws elbv2 describe-target-health \
    --target-group-arn "$tg" \
    --query 'TargetHealthDescriptions[].{Id:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason}' \
    --output table
}

case "$cmd" in
  status)
    echo "VIP: ${vip}:2101 (shared NLB, same region)"
    echo "Blue instance:  ${blue_id}"
    echo "Green instance: ${green_id}"
    tg_health
    ;;
  drain-blue)
    echo "Stopping ntripcaster on blue ${blue_id}..."
    ssm_run "$blue_id" "systemctl stop ntripcaster.service; echo stopped"
    echo "Wait ~20s for NLB unhealthy threshold..."
    sleep 25
    tg_health
    echo "New connections to ${vip} should use green only."
    ;;
  restore-blue)
    echo "Starting ntripcaster on blue ${blue_id}..."
    ssm_run "$blue_id" "systemctl start ntripcaster.service; sleep 2; systemctl is-active ntripcaster.service"
    echo "Wait ~20s for NLB healthy threshold..."
    sleep 25
    tg_health
    ;;
  drain-green)
    echo "Stopping ntripcaster on green ${green_id}..."
    ssm_run "$green_id" "systemctl stop ntripcaster.service; echo stopped"
    echo "Wait ~20s for NLB unhealthy threshold..."
    sleep 25
    tg_health
    echo "New connections to ${vip} should use blue only."
    ;;
  restore-green)
    echo "Starting ntripcaster on green ${green_id}..."
    ssm_run "$green_id" "systemctl start ntripcaster.service; sleep 2; systemctl is-active ntripcaster.service"
    echo "Wait ~20s for NLB healthy threshold..."
    sleep 25
    tg_health
    ;;
  *)
    echo "Usage: $0 {status|drain-blue|restore-blue|drain-green|restore-green}" >&2
    exit 1
    ;;
esac
