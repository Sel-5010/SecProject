#!/usr/bin/env bash
set -euo pipefail

# Lesson 3 - Fix verification
# Verifies that DVSA-ORDER-MANAGER can no longer invoke DVSA-ADMIN-GET-RECEIPT.

REGION="${REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"

ROLE_ARN=$(aws lambda get-function-configuration \
  --function-name DVSA-ORDER-MANAGER \
  --region "$REGION" \
  --query 'Role' \
  --output text)

echo "[*] Order Manager Role:"
echo "$ROLE_ARN"
echo

echo "[*] Simulating invoke permission against DVSA-ADMIN-GET-RECEIPT"
aws iam simulate-principal-policy \
  --policy-source-arn "$ROLE_ARN" \
  --action-names lambda:InvokeFunction \
  --resource-arns "arn:aws:lambda:$REGION:$ACCOUNT_ID:function:DVSA-ADMIN-GET-RECEIPT" \
  --region "$REGION" \
  --query 'EvaluationResults[*].{Action:EvalActionName,Resource:EvalResourceName,Decision:EvalDecision,Matched:MatchedStatements}' \
  --output json

echo
echo "[*] Expected fixed result: explicitDeny"
