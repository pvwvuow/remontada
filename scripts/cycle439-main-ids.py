#!/usr/bin/env python3
"""cycle-439: add id="main-content" to every page-level <main> element.
The skip link in src/app/layout.tsx targets #main-content; every route shell
(13 page.tsx + not-found.tsx + error.tsx) carries exactly one <main> with the
uniform opening `<main className="flex-1 ...`. This script rewrites that
opening tag to `<main id="main-content" className="flex-1 ...` and FAILS LOUD
unless exactly 15 files were touched, one replacement each — a partial or
double application would leave some routes without a skip target.
"""
import glob
import sys

PATTERN = '<main className="flex-1'
REPLACEMENT = '<main id="main-content" className="flex-1'

files = sorted(
    glob.glob("src/app/page.tsx")
    + glob.glob("src/app/*/page.tsx")
    + glob.glob("src/app/*/*/page.tsx")
    + ["src/app/not-found.tsx", "src/app/error.tsx"]
)
changed, already = [], []
for f in files:
    src = open(f, encoding="utf-8").read()
    n = src.count(PATTERN)
    if REPLACEMENT in src and n == 0:
        already.append(f)
        continue
    if n != 1:
        print(f"FAIL {f}: <main pattern count = {n} (expected 1)")
        sys.exit(1)
    open(f, "w", encoding="utf-8").write(src.replace(PATTERN, REPLACEMENT, 1))
    changed.append(f)

print(f"changed={len(changed)} already={len(already)}")
for f in changed:
    print(f"  + {f}")
for f in already:
    print(f"  = {f} (already had id)")
if len(changed) + len(already) != 15:
    print("FAIL: expected 15 <main> shells total")
    sys.exit(1)
# post-assert: every touched file now has exactly one id'd main
for f in files:
    src = open(f, encoding="utf-8").read()
    if src.count(REPLACEMENT) != 1:
        print(f"FAIL post-assert {f}")
        sys.exit(1)
print("OK 15/15 mains now targetable by the skip link")
