# DVSA Project Repository

This repository is organized for the ICS-344 DVSA Vulnerability Discovery and Remediation project.

## Project Goal
Document, exploit, fix, and verify the 10 official DVSA vulnerabilities in a clean, reproducible way.

## Recommended Workflow
1. Deploy DVSA in a non-production AWS account.
2. Collect setup screenshots and save them under `evidence/setup/` if needed.
3. For each lesson:
   - reproduce the issue
   - save screenshots, logs, and terminal output in the matching `evidence/lesson-XX/`
   - save code or policy fixes in `patches/`
   - update the report draft using the 10-part structure
   - verify the fix and save post-fix evidence
4. Keep secrets redacted before pushing anything to GitHub.

## Repository Layout
- `report/` - final report assets, figures, and tables
- `slides/` - presentation files
- `evidence/` - screenshots, logs, request output, and proof per lesson
- `patches/` - code diffs, policy files, and fixed versions
- `scripts/` - helper scripts for reproduction and verification
- `templates/` - markdown templates for report sections and evidence tracking
- `docs/` - extra notes, architecture diagrams, or planning docs

## Suggested Naming
Use consistent filenames so grading is easy.

Examples:
- `evidence/lesson-01/01-api-stage-url.png`
- `evidence/lesson-01/02-rce-request.txt`
- `evidence/lesson-01/03-cloudwatch-proof.png`
- `patches/lesson-02-order-manager-before.js`
- `patches/lesson-02-order-manager-after.js`
- `patches/lesson-07-iam-policy-before.json`
- `patches/lesson-07-iam-policy-after.json`

## Lessons
1. Event Injection
2. Broken Authentication
3. Sensitive Information Disclosure
4. Insecure Cloud Configuration
5. Broken Access Control
6. Denial of Service
7. Over-Privileged Function
8. Logic Vulnerabilities
9. Vulnerable Dependencies
10. Unhandled Exceptions

## Before You Push
- Remove real AWS keys, session tokens, JWTs, passwords, and emails.
- Redact account IDs if your instructor expects that.
- Keep only screenshots and logs that support your findings.
- Make sure every lesson has exploit proof, fix proof, and post-fix verification.
