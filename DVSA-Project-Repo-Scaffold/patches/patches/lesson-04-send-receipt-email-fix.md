# Lesson 4 Patch - Insecure Cloud Configuration

## File Changed

```text
DVSA-SEND-RECEIPT-EMAIL/send_receipt_email.py
```

## Problem

The original Lambda function processed S3 object keys without strict validation. The object key was split and trusted directly:

```python
order = key.split("/")[3]
orderId = order.split("_")[0]
userId = order.split("_")[1].replace(".raw", "")
```

This is unsafe because the S3 object key is attacker-controlled input.

The original function also used `os.system()` to write receipt content:

```python
os.system(f'echo -e "\t----------------------\n\t\tDate: {date}" >> ' + download_path)
```

Using shell commands inside Lambda is risky when the workflow also processes attacker-influenced object names or file paths.

## Fix Summary

The fix adds an allowlisted receipt object-key format and rejects anything suspicious before receipt processing continues.

The accepted object-key format is:

```text
YYYY/MM/DD/orderId_userId.raw
```

Example accepted key:

```text
2026/05/04/order123_user456.raw
```

Example rejected key:

```text
2026/05/04/null_;echo DVSA_LESSON4_MARKER;echo x.raw
```

## Code Added

At the top of the file:

```python
import re

SAFE_KEY = re.compile(
    r"^\d{4}/\d{2}/\d{2}/(?P<orderId>[A-Za-z0-9._-]+)_(?P<userId>[A-Za-z0-9._-]+)\.raw$"
)
```

Inside `lambda_handler`, immediately after decoding the S3 key:

```python
match = SAFE_KEY.fullmatch(key)
if not match:
    print("Rejected suspicious receipt key:", key)
    return {"status": "err", "msg": "invalid receipt object key"}

orderId = match.group("orderId")
userId = match.group("userId")
```

The unsafe shell command was replaced with normal Python file writing:

```python
with open(download_path, "a", encoding="utf-8") as f:
    f.write(f"\t----------------------\n\t\tDate: {date}\n")
```

## Fixed Code Reference

The important fixed logic is:

```python
bucket = event['Records'][0]['s3']['bucket']['name']
key = event['Records'][0]['s3']['object']['key']
key = urllib.parse.unquote_plus(urllib.parse.unquote(key))

match = SAFE_KEY.fullmatch(key)
if not match:
    print("Rejected suspicious receipt key:", key)
    return {"status": "err", "msg": "invalid receipt object key"}

orderId = match.group("orderId")
userId = match.group("userId")
```

## Verification

After deploying the patched Lambda, I uploaded a suspicious object key:

```bash
aws s3 cp ~/dvsa_lesson4_empty "s3://dvsa-receipts-bucket-836739852202-us-east-1/2026/05/04/null_;echo DVSA_LESSON4_MARKER;echo x.raw"
```

CloudWatch showed:

```text
Rejected suspicious receipt key
```

This confirms that suspicious object names are rejected before backend receipt processing.

## Security Improvement

The Lambda now treats S3 object keys as untrusted input. Suspicious object names are rejected early, and shell command construction is removed from the receipt header-writing logic.
