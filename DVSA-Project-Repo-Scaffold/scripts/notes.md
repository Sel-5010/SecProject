## Lesson 2 - Broken Authentication

### Purpose
Demonstrate that DVSA trusts JWT payload claims such as `username` and `sub` without properly verifying the JWT signature, allowing User B to impersonate User C and access User C’s order data. After the fix, forged tokens should be rejected while valid tokens should still work normally.

### Environment
- API endpoint: `/order`
- Users used:
  - User B = attacker
  - User C = victim
- Both users placed at least one order
- Tools:
  - Browser DevTools
  - curl
  - python3
  - jq

### Reproduction summary
1. Capture `TOKEN_B` from DevTools while logged in as User B.
2. Capture `TOKEN_C` from DevTools while logged in as User C.
3. Decode both JWTs to extract `username` and `sub`.
4. Confirm normal behavior using `TOKEN_B` with `{"action":"orders"}`.
5. Forge a token by modifying User B’s payload to use User C’s `username` and `sub`.
6. Send the forged token to the Orders API.
7. Confirm the response returns User C’s order list.

### Main commands
```bash
export API="https://<api-id>.execute-api.us-east-1.amazonaws.com/dvsa/order"
export TOKEN_B="<User B JWT>"
export TOKEN_C="<User C JWT>"
