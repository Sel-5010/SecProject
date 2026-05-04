# Lesson 6: Denial of Service Fix Notes

## Vulnerability

The DVSA billing workflow became unreliable during controlled concurrent billing requests. The test sent 12 parallel billing requests using:

```text
scripts/lesson-06/lesson6_dos_controlled.py
