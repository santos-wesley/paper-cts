# PRISMA flow — as executed (2026-07-08)

```
IDENTIFICATION
  arXiv                    272
  OpenAlex                 487
  Semantic Scholar         364
  ---------------------------
  Records identified      1123
        |
        |  duplicates removed (cross-database, by normalized title):  577
        v
SCREENING
  Records screened         546
        |
        |  excluded at screening: 88
        |     E1  not AI/LLM (human/organisational/political/literary):  78
        |     E2  sycophancy stem absent (off-target):                   10
        v
ELIGIBILITY
  Assessed for eligibility 458
        |
        |  excluded at eligibility: 211
        |     E3  sycophancy not the central topic (not in title)
        v
INCLUDED
  Studies included         247
        (127 with abstract retrieved; 120 assessed on title metadata)
```

Lusophone probe (OpenAlex, title/abstract): sicofância = 0; bajulação = 0;
adulação = 0.

Numbers are produced by `scripts/03_screen.ps1` and stored machine-readably in
`data/processed/prisma_counts.json`.
