# Codebook

## `data/raw/{arxiv,openalex,semanticscholar}.json`
Array of records as returned by each database, normalized to a common shape:

| field | meaning |
|---|---|
| `source` | database of origin (`arXiv` / `OpenAlex` / `SemanticScholar`) |
| `ext_id` | native identifier (arXiv id, OpenAlex work id, or S2 paperId) |
| `doi` | DOI (may be empty for arXiv preprints) |
| `arxiv_id` | arXiv identifier where available |
| `title` | work title |
| `year` | publication / submission year |
| `abstract` | abstract as returned by the API (OpenAlex omitted; see README) |
| `url` | canonical URL |

## `data/processed/pooled_dedup.{json,csv}`
The three sources pooled and deduplicated by **normalized title** (lowercase,
alphanumeric only). Merged records keep the longest abstract and list every
source that returned the work.

| field | meaning |
|---|---|
| `rec_id` | stable record id assigned after dedup (`R0001` …) |
| `title`, `year`, `doi`, `arxiv_id`, `abstract`, `url` | as above (merged) |
| `sources` | `+`-joined list of databases that returned the work |

## `data/processed/screening_decisions.csv`
One row per unique record (n = 546); the full audit trail of the selection.

| field | meaning |
|---|---|
| `rec_id` | record id |
| `year`, `sources`, `has_abstract`, `title` | metadata |
| `decision` | `include` / `exclude` |
| `stage` | `screening` / `eligibility` / `included` |
| `reason` | exclusion reason code (empty if included) |

### Reason codes
| code | stage | meaning |
|---|---|---|
| `E2 not-sycophancy` | screening | the stem "sycophan" is absent (off-target match) |
| `E1 not-AI/LLM` | screening | sycophancy present but no AI/LLM cue (human/organisational/political/literary sycophancy) |
| `E3 sycophancy-not-central` | eligibility | sycophancy is only mentioned (not in the title); not the central concern of the work |
| *(empty)* | included | sycophancy in the title **and** an AI/LLM cue present |

### Inclusion/exclusion criteria (deterministic, lexical)
- **Sycophancy present:** title or abstract matches the regex stem `sycophan`.
- **AI/LLM cue present:** title or abstract contains at least one of a fixed list
  of cues (`language model`, `LLM`, `chatbot`, `RLHF`, `artificial intelligence`,
  `transformer`, `alignment`, `reward model`, `generative`, `vision-language`, …;
  the full list is in `scripts/03_screen.ps1`).
- **Central concern (eligibility):** the stem `sycophan` appears in the **title**.

## `data/processed/included_studies.csv`
The n = 247 included studies (sorted by year, descending).

## `data/processed/prisma_counts.json`
Machine-readable version of the PRISMA flow numbers (see `PRISMA.md`).
