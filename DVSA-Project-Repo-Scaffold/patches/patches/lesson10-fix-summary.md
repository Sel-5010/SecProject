# Lesson 10 Fix Summary — Unhandled Exceptions

## Vulnerability

The `/order` API returned raw backend Lambda exception details to the client when malformed requests were sent.

Example vulnerable request:

```json
{
  "action": "get"
}
