



# Lesson 2 - Broken Authentication

## Purpose
These scripts reproduce and verify DVSA Lesson 2, where the backend trusts JWT payload claims without properly verifying the signature.

## Required environment variables

Before running the scripts, set these:

```bash
export API="https://<api-id>.execute-api.us-east-1.amazonaws.com/dvsa/order"
export TOKEN_B="<User B JWT>"
export TOKEN_C="<User C JWT>"
