# Manifest

Complete inventory of this anonymized review mirror.

| File | Description | Status |
|---|---|---|
| `README.md` | Front page (anonymized) | ✔ |
| `TAXONOMY_CONSTRUCTION_RECORD.md` | Construction record of the seven-axis taxonomy | ✔ |
| `MANIFEST.md` | This inventory | ✔ |
| `PRISMA.md` | PRISMA-ScR reporting | ✔ |
| `CODEBOOK.md` | Coding scheme | ✔ |
| `ENVIRONMENT.md` | Execution environment | ✔ |
| `LICENSE` | Dual MIT / CC-BY 4.0 (holder anonymized) | ✔ |
| `.gitignore` | Ignore rules | ✔ |
| `scripts/01_search.ps1` | Search (arXiv, OpenAlex, Semantic Scholar); API contact anonymized | ✔ |
| `scripts/02_dedup.ps1` | Deduplication by normalized title | ✔ |
| `scripts/03_screen.ps1` | Deterministic screening/eligibility rules (full cue list) | ✔ |
| `scripts/04_ground.ps1` | Grounding pass for the taxonomy's empirical axes | ✔ |
| `data/search_log.json` | Executed-search log | ✔ |
| `data/raw/arxiv.json` | 272 raw records (2026-07-08) | ✔ |
| `data/raw/openalex.json` | 487 raw records (2026-07-08) | ✔ |
| `data/raw/semanticscholar.json` | 364 raw records (2026-07-08) | ✔ |
| `data/processed/pooled_dedup.csv` / `.json` | Deduplicated pool (546) | ✔ |
| `data/processed/screening_decisions.csv` | Per-record decisions, exclusion codes E1/E2/E3 | ✔ |
| `data/processed/included_studies.csv` | Final corpus (247) | ✔ |
| `data/processed/taxonomy_evidence.csv` | Evidence table grounding the empirical axes | ✔ |
| `data/processed/grounding_report.txt` | Grounding pass report (n = 339 abstracts) | ✔ |
| `data/processed/prisma_counts.json` | PRISMA flow counts | ✔ |

**Excluded from this mirror** (present only in the archived deposit, to preserve anonymity): version-control history, `CITATION.cff`, deposit metadata (`zenodo.json`, `dist/`), and packaging/deposit scripts (`build_archive.ps1`, `deposit_zenodo.ps1`).
