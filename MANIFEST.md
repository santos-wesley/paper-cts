# Manifest

Complete inventory of this anonymized review mirror.

| File | Description | Status |
|---|---|---|
| `README.md` | Front page (anonymized) | ✔ |
| `TAXONOMY_CONSTRUCTION_RECORD.md` | Construction record of the seven-axis taxonomy | ✔ |
| `MANIFEST.md` | This inventory | ✔ |
| `PRISMA.md` | PRISMA-ScR reporting | ✔ |
| `CODEBOOK.md` | Coding scheme | ✔ |
| `PUBLISHED_DIALOGUES.md` | Catalogue of published dialogues coded with the taxonomy (Section 6) | ✔ |
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
| `data/processed/included_studies.csv` | Studies included by the lexical rules (247); refined in revision R1 (see below) | ✔ |
| `data/processed/taxonomy_evidence.csv` | Lexical check of the empirical axes in the corpus (indicative) | ✔ |
| `data/processed/grounding_report.txt` | Report of the lexical check (n = 339 abstracts) | ✔ |
| `data/processed/prisma_counts.json` | PRISMA flow counts (original screening) | ✔ |

**Revision R1 additions**

| File | Description | Status |
|---|---|---|
| `CHARTING_INSTRUCTIONS.md` | Operational coding instructions used for the charting | ✔ |
| `scripts/05_enrich.ps1` | Recovers missing abstracts and document-type metadata (Zenodo, OpenAlex, Semantic Scholar, Crossref, arXiv) | ✔ |
| `scripts/06_eligibility.ps1` | Applies E4 (not a research output), E5 (no abstract) and duplicate-version removal | ✔ |
| `scripts/07_verification_sample.ps1` | Draws the blind 20% verification sample (seed 94) | ✔ |
| `scripts/08_agreement.ps1` | Pairwise agreement among the first-pass charting and the two independent recodings | ✔ |
| `scripts/09_charting_summary.ps1` | Descriptive profile of the charted corpus | ✔ |
| `data/processed/enriched_included.csv` / `.json` | Included studies with document-type metadata and best available abstract (247) | ✔ |
| `data/processed/doctype_review.csv` | Title/abstract exclusions (E4b) and duplicate versions, each with its reason | ✔ |
| `data/processed/eligibility_decisions.csv` | Per-record R1 eligibility decision and source kind | ✔ |
| `data/processed/eligible_studies.csv` | Studies eligible for charting (181) | ✔ |
| `data/processed/prisma_counts_r1.json` | PRISMA flow counts including R1 criteria | ✔ |
| `data/processed/charting.csv` | Abstract-level charting of the 181 eligible studies (AI-assisted first pass) | ✔ |
| `data/processed/charting_summary.csv` | Counts per field and value | ✔ |
| `data/processed/charting_verification_blind.csv` | Verification sample for independent recoding (codes hidden) | ✔ |
| `data/processed/charting_verification_key.csv` | First-pass codes of the verification sample | ✔ |
| `data/processed/charting_verification_coder1.csv` / `coder2.csv` | Independent recodings of the verification sample by two external coders (AI pre-classification, then manual inspection) | ✔ |
| `data/processed/charting_verification_merged.csv` | First pass and both recodings side by side | ✔ |
| `data/processed/charting_agreement.csv` | Pairwise agreement per field | ✔ |
| `data/processed/charting_agreement_labels.csv` | Pairwise agreement per label (multi-label fields) | ✔ |
| `PARTICIPATION_INSTRUCTIONS.md` | Coding instructions for the full-text participation charting | ✔ |
| `scripts/10_fulltext.ps1` | Retrieves open-access full texts (arXiv, Zenodo, OpenAlex) to a local cache and records their provenance | ✔ |
| `scripts/11_participation_summary.ps1` | Summary of the participation charting and validation of author countries against OpenAlex | ✔ |
| `data/processed/fulltext_status.csv` | Provenance of each full text (PDFs not redistributed) | ✔ |
| `data/processed/metadata_affiliations.csv` | Affiliations recorded by OpenAlex and Zenodo (validation only) | ✔ |
| `data/processed/participation.csv` | Full-text participation charting of the 181 eligible studies (AI-assisted) | ✔ |
| `data/processed/participation_summary.csv` | Counts per field and value of the participation charting | ✔ |
| `data/processed/participation_validation.csv` | Author countries: charting vs. OpenAlex | ✔ |

**Excluded from this mirror** (present only in the archived deposit, to preserve anonymity): version-control history, `CITATION.cff`, deposit metadata (`zenodo.json`, `dist/`), and packaging/deposit scripts (`build_archive.ps1`, `deposit_zenodo.ps1`).
