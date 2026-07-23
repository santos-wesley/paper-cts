# Reproducible Search, Screening and Taxonomy-Construction Materials

Anonymized supplementary repository for the manuscript *Algorithmic Cordiality: Sycophancy in Language Models as a Sociotechnical Problem*, under double-blind review at the Revista Brasileira de Estudos CTS.

This repository mirrors, for review purposes, an archived open deposit (citable DOI withheld for blind review; it will be referenced in the final version). It contains everything needed to audit and re-run the systematic scoping search reported in the manuscript's Section 3, and the construction record of the seven-axis taxonomy presented in Section 6.

## Contents

| Path | What it is |
|---|---|
| `TAXONOMY_CONSTRUCTION_RECORD.md` | Full construction record of the taxonomy: method, meta-characteristic, iteration modes, per-axis derivation and grounding, ending-condition checks, design decisions, revision notes |
| `PRISMA.md` | PRISMA-ScR reporting of the selection flow |
| `CODEBOOK.md` | Coding scheme for the screening and grounding passes |
| `ENVIRONMENT.md` | Execution environment for re-running the scripts |
| `MANIFEST.md` | Inventory of every file |
| `scripts/01_search.ps1` … `04_ground.ps1` | Re-runnable search, deduplication, screening and grounding scripts |
| `data/search_log.json` | Log of the executed search |
| `data/raw/` | Raw records as retrieved on 2026-07-08: arXiv (272), OpenAlex (487), Semantic Scholar (364) |
| `data/processed/` | Deduplicated pool (546), `screening_decisions.csv` (per-record decisions with exclusion codes), `included_studies.csv` (247), `taxonomy_evidence.csv` + `grounding_report.txt` (grounding of the taxonomy's empirical axes), `prisma_counts.json` |
| `LICENSE` | Dual licence: code MIT, derived data CC-BY 4.0 (copyright holder anonymized for review) |

## Search summary

Search executed 8 July 2026 on arXiv, OpenAlex and Semantic Scholar. Selection flow: 1,123 records identified; 577 duplicates removed (normalized title); 88 excluded at screening (E1 not AI/LLM: 78; E2 off-target: 10); 211 excluded at eligibility (E3 sycophancy not central); 247 studies included. Screening and eligibility used deterministic, re-runnable lexical rules (full cue list in `scripts/03_screen.ps1`), so every decision can be audited and re-run rather than resting on unrecorded judgment. A Lusophone probe (sicofância, bajulação, adulação) returned 0 records in these indexes.

## Re-running

See `ENVIRONMENT.md`. Running the four scripts in order reproduces the flow above; counts may drift slightly as the databases grow. The OpenAlex polite-pool contact address in `scripts/01_search.ps1` has been replaced by a placeholder for anonymization; substitute any address before re-running.

## Anonymization note

For double-blind review, this mirror excludes the archived deposit's citation metadata (`CITATION.cff`, deposit descriptors), its packaging/deposit tooling, and version-control history, and anonymizes the copyright holder and the API contact address. Nothing affecting reproducibility was altered: queries, data, decisions and scripts are byte-identical to the deposit except for the two anonymized strings noted here.
