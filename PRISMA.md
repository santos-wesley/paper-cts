# PRISMA flow as executed (2026-07-08)

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

---

# Revision R1: refined eligibility and charting

The lexical rules above admit any document whose title contains the
sycophancy stem, including items that are not research outputs (a podcast
episode, datasets, supplementary materials, a news article) and several
versions of the same work. Revision R1 adds three steps after the original
eligibility stage (scripts `05_enrich.ps1` and `06_eligibility.ps1`):

```
INCLUDED BY LEXICAL RULES      247
        |
        |  duplicate versions removed (same DOI/arXiv id or revised title):   9
        |  E4 not a research output:                                          10
        |       E4a  repository metadata (datasets, editorial):                4
        |       E4b  title/abstract review (podcast, data deposits, news):     6
        |  E5 no abstract retrievable from any open source:                  47
        v
ELIGIBLE FOR CHARTING          181
```

Abstracts missing from the original records were recovered from Zenodo,
OpenAlex, Semantic Scholar, Crossref and arXiv (188 of the 247 have an
abstract; provenance in `enriched_included.csv`). The 181 eligible studies
were charted at abstract level (`charting.csv`, scheme in `CODEBOOK.md` and
`CHARTING_INSTRUCTIONS.md`); an AI-assisted first pass is checked against an
independent recoding of a random 20% sample (`07_verification_sample.ps1`,
`08_agreement.ps1`).

Machine-readable counts: `data/processed/prisma_counts_r1.json`.
