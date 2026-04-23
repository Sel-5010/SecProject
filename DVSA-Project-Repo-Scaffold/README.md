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
- `docs/` - planning docs


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
