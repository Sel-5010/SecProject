# Lessons 1 and 9 Notes

## Shared exploit path
Both lessons use the same `/order` exploit path in DVSA.

## Lesson 1 focus
Event Injection:
- proves attacker-controlled input executed in the backend
- main proof is the CloudWatch log entry:
  `FILE READ SUCCESS: You are reading the contents of my hacked file!`

## Lesson 9 focus
Vulnerable Dependencies:
- proves the exploit was possible because the backend used an unsafe third-party dependency
- main dependency evidence is the use of `node-serialize` on attacker-controlled request data

## Shared fix
The root fix is in:
- `patches/lesson1&9.fix`

The fix:
- removes unsafe deserialization
- stops using the unsafe dependency in the request path
- parses request data as normal JSON only

## Shared post-fix proof
After the fix:
- the same exploit payload no longer causes backend execution
- the `FILE READ SUCCESS` log entry no longer appears
- normal order-related DVSA behavior still works

# Lesson 2 - Broken Authentication

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
```

# Lesson 7 - Over-Privileged Function

## Vulnerability
The Lambda function DVSA-SEND-RECEIPT-EMAIL used an execution role with permissions broader than required for sending receipt emails.

## Root Cause
The execution role had excessive IAM permissions. It allowed broad S3 access, broad DynamoDB access, and full SES access. Any code running inside the Lambda function would inherit these permissions.

## Evidence Collected
- The role had AmazonSESFullAccess with ses:* on all resources.
- The role had S3 wildcard permissions on arn:aws:s3:::* and arn:aws:s3:::*/*.
- The role had DynamoDB wildcard permissions on all tables and indexes.
- IAM Policy Simulator showed unrelated S3 access was allowed before remediation.
- CloudWatch Logs confirmed the receipt Lambda function was invoked.
- After remediation, IAM Policy Simulator showed unrelated S3 and DynamoDB actions were denied.
- CloudWatch Logs confirmed the receipt Lambda still ran after the fix.

## Fix
Removed broad SES, S3, and DynamoDB permissions. Added a least-privilege policy named DVSA-SendReceipt-LeastPrivilege.

## Verification
After the fix, unrelated S3 and DynamoDB actions were denied in IAM Policy Simulator, while the normal receipt workflow still triggered the Lambda function successfully.
