API="https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/YOUR_STAGE/order"
TOKEN="PASTE_REDACTED_TOKEN_HERE"

echo
echo "============================================================"
echo "Lesson 10 - Reproduce Unhandled Exception"
echo "============================================================"
echo
echo "[*] Target API:"
echo "$API"
echo
echo "[*] Sending malformed request:"
echo '{ "action": "get" }'
echo
echo "[*] This request is missing the required order-id field."
echo

curl -s "$API" \
  -H "content-type: application/json" \
  -H "authorization: $TOKEN" \
  --data-raw '{
    "action": "get"
  }' | jq

echo
echo "============================================================"
echo "What to look for before the fix:"
echo "============================================================"
echo "- stackTrace"
echo "- errorType"
echo "- errorMessage"
echo "- /var/task/"
echo "- internal Lambda file paths"
echo "- source-code line references"
echo
echo "Take screenshot:"
echo "evidence/lesson-10/lesson10_01_malformed_request_leak.png"
echo "============================================================"
