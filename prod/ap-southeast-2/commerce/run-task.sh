#!/usr/bin/env bash
# Runs one ECS task to completion and fails unless its container exits 0. Called by terraform_data.
set -euo pipefail
: "${REGION:?}" "${CLUSTER:?}" "${TASK_DEFINITION:?}" "${CAPACITY_PROVIDER:?}" "${SUBNETS:?}" "${SECURITY_GROUP:?}"

ecs() { aws ecs --region "$REGION" "$@"; }

# A role Terraform just created can be unusable for a few seconds (IAM is eventually consistent), so retry only that error.
attempts=6
for i in $(seq 1 "$attempts"); do
  if out=$(ecs run-task --cluster "$CLUSTER" --task-definition "$TASK_DEFINITION" \
    --capacity-provider-strategy "capacityProvider=$CAPACITY_PROVIDER,weight=1" \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
    --started-by terraform --query 'tasks[0].taskArn' --output text 2>&1); then
    task=$out
    break
  fi
  case "$out" in
    *"unable to assume the role"*) ;;
    *) echo "$out" >&2; exit 1 ;;
  esac
  if [ "$i" -eq "$attempts" ]; then
    echo "$out" >&2
    echo "role still not usable after $attempts attempts" >&2
    exit 1
  fi
  echo "role not usable yet, retrying ($((i + 1))/$attempts)"
  sleep "${RETRY_SLEEP:-10}"
done
[ "$task" != "None" ] || { echo "run-task started no task" >&2; exit 1; }
echo "started $task"

# Fargate starts the task in about a minute.
status=""
for _ in $(seq 1 40); do
  status=$(ecs describe-tasks --cluster "$CLUSTER" --tasks "$task" --query 'tasks[0].lastStatus' --output text)
  [ "$status" = "STOPPED" ] && break
  sleep 15
done
if [ "$status" != "STOPPED" ]; then
  ecs stop-task --cluster "$CLUSTER" --task "$task" --reason "timed out in terraform" > /dev/null
  echo "task still $status after 10 minutes, stopped it" >&2
  exit 1
fi

code=$(ecs describe-tasks --cluster "$CLUSTER" --tasks "$task" --query 'tasks[0].containers[0].exitCode' --output text)
if [ "$code" != "0" ]; then
  reason=$(ecs describe-tasks --cluster "$CLUSTER" --tasks "$task" --query 'tasks[0].stoppedReason' --output text)
  echo "task failed: exit code $code, $reason. Container output is in CloudWatch Logs." >&2
  exit 1
fi
echo "task finished with exit code 0"
