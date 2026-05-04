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
# Lesson 3 Notes

## Vulnerability

Sensitive Information Disclosure.

## Affected components

- Public API path: `/order`
- Public Lambda: `DVSA-ORDER-MANAGER`
- Privileged Lambda: `DVSA-ADMIN-GET-RECEIPT`
- Storage: DVSA receipts S3 bucket
- Output exposed: signed S3 URL for receipt ZIP file

## Exploit summary

Lesson 3 reused the vulnerable `/order` path.  
A crafted request caused `DVSA-ORDER-MANAGER` to invoke the privileged admin receipt function:

`DVSA-ADMIN-GET-RECEIPT`

That function generated a signed S3 URL for a receipt ZIP file.  
The signed URL was copied from the response/log output and used with `curl -L` to download:

`lesson3-receipts.zip`

Then `unzip -l lesson3-receipts.zip` confirmed that the ZIP file was accessible.

## Main proof

The main proof before the fix was:

- signed S3 receipt ZIP URL was returned
- `curl -L` successfully downloaded the ZIP
- `unzip -l` listed the ZIP contents

Important evidence files:

- `evidence/lesson-03/L03-03-signed-url-response.png`
- `evidence/lesson-03/L03-04-downloaded-zip-listing.png`

## Root cause

The public order-processing Lambda could reach a privileged admin receipt-export function.  
This broke the intended authorization boundary because a normal public workflow should not be able to generate admin receipt ZIP download links.

## Fix

An explicit IAM deny policy was added to the execution role used by:

`DVSA-ORDER-MANAGER`

The policy denies:

`lambda:InvokeFunction`

on:

`arn:aws:lambda:us-east-1:836739852202:function:DVSA-ADMIN-*`

This includes:

`DVSA-ADMIN-GET-RECEIPT`

## Fix files

- `patches/patches/lesson-03-deny-dvsa-admin-invoke.json`
- `patches/patches/lesson-03-role-after.txt`
- `patches/patches/lesson-03-policy-simulation-after.json`

## Verification

The fix was verified with IAM policy simulation.

The simulation checked whether the `DVSA-ORDER-MANAGER` role could invoke:

`DVSA-ADMIN-GET-RECEIPT`

The result was:

`explicitDeny`

This proves that the receipt ZIP disclosure path is blocked after the fix.

Important evidence file:

- `evidence/lesson-03/L03-07-policy-simulator-explicit-deny.png`

## Takeaway

Sensitive receipt data should only be exposed through authorized receipt or admin workflows.  
In serverless applications, IAM permissions are part of the security boundary.  
Even if one Lambda is abused, it should not be able to invoke privileged admin functions unless that access is strictly required.

# Lesson 5 - Broken Access Control

## Purpose

Demonstrate that DVSA allows a normal user to abuse the public `/order` API path to indirectly invoke the privileged `DVSA-ADMIN-UPDATE-ORDERS` Lambda function. This allows the user to update an order state without completing the normal billing workflow.

After the fix, the same exploit should no longer update the order, while normal billing should still work.

## Environment

- API endpoint: `/order`
- Public Lambda function: `DVSA-ORDER-MANAGER`
- Privileged Lambda function: `DVSA-ADMIN-UPDATE-ORDERS`
- User used: normal non-admin DVSA user
- Tools:
  - Browser DevTools
  - curl
  - python3
  - jq
  - AWS Console
  - IAM

## Reproduction summary

1. Logged in to DVSA as a normal user.
2. Captured the `/order` API URL and authorization token using browser DevTools.
3. Created a new order.
4. Added shipping details.
5. Did not complete billing.
6. Generated an injected payload that invoked `DVSA-ADMIN-UPDATE-ORDERS`.
7. Sent the payload to the public `/order` endpoint.
8. Refreshed the DVSA orders page.
9. Confirmed that the target order changed to `processed` even though normal billing was not completed.

## Evidence

Minimum screenshots used:

1. `01-devtools-api-token.png`  
   Shows the `/order` API request and authorization header.

2. `02-before-exploit-unpaid.png`  
   Shows the order before exploit, after shipping but before billing.

3. `03-exploit-terminal.png`  
   Shows the exploit request being sent.

4. `04-after-exploit-paid.png`  
   Shows the attacked order changed to `processed`.

5. `05-iam-fix-policy.png`  
   Shows the IAM deny policy added to the `DVSA-ORDER-MANAGER` execution role.

6. `06-postfix-verification.png`  
   Shows that after the fix the exploit no longer changes a new order, and normal billing still works.

## Root cause

The root cause is missing access control between public and privileged backend functions. The public order manager path should not be able to trigger administrative order updates. Because the public function can invoke the admin update function, an attacker who reaches code execution in the public function can perform a privileged order-state transition.

## Fix applied

An inline IAM deny policy was added to the execution role of `DVSA-ORDER-MANAGER`.

The policy denies:

- `lambda:InvokeFunction`

against:

- `DVSA-ADMIN-UPDATE-ORDERS`

This prevents the public order manager function from invoking the privileged admin update function.

## Patch file

Patch saved in:

```text
```
patches/patches/lesson-05-iam-deny-admin-update.json

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
