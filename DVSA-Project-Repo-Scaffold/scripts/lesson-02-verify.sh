

# =========================================================
# Lesson 2 - Broken Authentication
# Verification script after fix
# =========================================================

echo "[*] Lesson 2 - Broken Authentication verification after fix"

# Step 0: helper function to ensure required variables exist
require_var() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "[!] Missing required environment variable: $name"
    exit 1
  fi
}

# Step 1: confirm required variables are available
# API       = /order endpoint
# TOKEN_B   = real valid token
# FAKE_AS_C = forged token created during reproduction
require_var API
require_var TOKEN_B
require_var FAKE_AS_C

echo
echo "=============================="
echo "Step 1 - Forged token should fail after the fix"
echo "=============================="

# Expected result after fix:
# error such as "invalid token"
curl -s "$API" \
  -H "content-type: application/json" \
  -H "authorization: $FAKE_AS_C" \
  --data-raw '{"action":"orders"}' | jq

echo
echo "=============================="
echo "Step 2 - Real valid token should still work"
echo "=============================="

# Expected result after fix:
# TOKEN_B still returns User B's own orders
curl -s "$API" \
  -H "content-type: application/json" \
  -H "authorization: $TOKEN_B" \
  --data-raw '{"action":"orders"}' | jq

echo
echo "[*] Verification steps finished."
