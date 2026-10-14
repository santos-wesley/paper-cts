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

---

# Revision R1 additions

The steps below were added during the first revision round. They do not change
the search (01) or the lexical screening (02–03); they refine the included set
and chart it.

## `data/processed/enriched_included.{json,csv}` (script `05_enrich.ps1`)
One row per study included by `03_screen.ps1` (n = 247), with document-type
metadata and the best available abstract. Every field records its provenance.

| field | meaning |
|---|---|
| `openalex_type`, `openalex_source`, `openalex_source_type`, `openalex_language` | OpenAlex work type, host source and its type, detected language |
| `zenodo_status` | `available`, or `unavailable (HTTP <code>)` when Zenodo no longer serves the record (e.g., 410 Gone for removed deposits) |
| `zenodo_type`, `zenodo_subtype` | Zenodo `resource_type` (Zenodo DOIs only) |
| `s2_publication_types`, `s2_venue` | Semantic Scholar metadata (queried only when the abstract was missing) |
| `crossref_type` | Crossref work type (queried only when the abstract was missing) |
| `abstract_source` | where the abstract came from: `pooled` (original records), `zenodo`, `openalex`, `semanticscholar`, `crossref`, `arxiv`, or empty |
| `abstract` | abstract text (markup removed) |

## `data/processed/eligibility_decisions.csv` (script `06_eligibility.ps1`)
One row per study in the enriched set, with the R1 eligibility decision.

| code | meaning |
|---|---|
| `E4a <source>:<type>` | not a research output according to repository metadata. Excluded types: Zenodo `dataset`, `presentation`, `poster`, `image`, `video`, `audio`, `software`, `lesson`; OpenAlex `dataset`, `paratext`, `peer-review`, `erratum`, `retraction`, `editorial`, `supplementary-materials`, `libguides`, `grant`; Crossref `dataset`, `peer-review`, `component`, `grant` |
| `E4b <reason>` | not a research output according to title/abstract review (e.g., podcast episode, newsletter or blog post, product or marketing page). Each exclusion is listed with its reason in `doctype_review.csv` |
| `E5 no-abstract` | no abstract retrievable from any open source; the record cannot be charted |
| `DUP <reason>` | another version of the same work is already in the set (same DOI or arXiv id, or a revised title of the same work). The most complete version is kept: peer-reviewed over preprint, with abstract over without. Listed in `doctype_review.csv` with code `DUP` |

E4a is not applied to records with an arXiv id: arXiv only hosts research
papers, and some arXiv records carry the DOI of an accompanying dataset.

`source_kind` is derived without judgement and says where the version in the
set appeared: `journal-or-proceedings` (OpenAlex journal/conference source,
Crossref journal-article/proceedings-article/book-chapter, or a publisher DOI
prefix; never for records typed as preprints), then `arXiv`, `Zenodo`, `SSRN`,
`OSF`, `other-repository`, `no-identifier`. A journal or proceedings version
takes precedence over an arXiv copy. `journal-or-proceedings` is not the same
as peer-reviewed research: viewpoints and editorials also appear in journals.

**No quality appraisal is performed.** As is usual in scoping reviews, records
are not excluded for methodological quality; `source_kind` lets readers
restrict any count to work published in journals or proceedings.

## `data/processed/charting.csv`
Abstract-level charting of every eligible study. One row per study.

Coding rules: code **only what the abstract states**; use `not-stated` when
the abstract is silent; do not infer from titles of other works, author
affiliations, or general knowledge of the field. Multi-label fields are
`;`-separated. The operational instructions given to the coders, with the
decision rules for borderline cases, are in `CHARTING_INSTRUCTIONS.md`.

Harmonization rule applied after the first pass: in `human-subjects` studies
the LLM is an experimental stimulus, not an object in which sycophancy is
measured, so `model_families` and `modality` are `n/a`; the model name is kept
in `models_named`, and the row's `notes` record the harmonization. Models used
only as judges or evaluators are not coded as tested models.

| field | values |
|---|---|
| `study_type` (single) | `empirical-evaluation` (measures sycophancy in one or more models: benchmark, experiment, audit); `mitigation` (proposes and tests a method to reduce it); `mechanistic` (internal representations, probing, steering as analysis); `human-subjects` (participants: perceptions, effects on users); `conceptual` (theoretical, normative or position paper without a new empirical test); `review`; `protocol` (preregistration or study protocol, no results yet); `other` |
| `paradigm` (multi) | `opinion-identity-cue` (user opinion, identity or persona in the prompt); `challenge-rebuttal` (pushback in a later turn, "are you sure?", rebuttals); `feedback-praise` (evaluation of user-attributed work, praise); `false-premise-mimicry` (user error or false presupposition embedded in the prompt); `social-face` (advice, validation, moral judgement, face preservation); `internal-probe` (probing or steering internal representations); `other`; `not-stated`; `n/a` for conceptual and review papers |
| `model_families` (multi) | `openai`, `anthropic`, `google`, `meta-llama`, `mistral`, `qwen`, `deepseek`, `other`, `not-stated`, `n/a` |
| `models_named` | models as named in the abstract, `;`-separated (empty if none) |
| `domain` (multi) | `general-factual`, `math-reasoning`, `code`, `medicine-health`, `mental-health`, `education`, `law`, `politics-opinion`, `advice-interpersonal`, `science`, `agents-memory`, `llm-as-judge`, `other`, `not-stated` |
| `modality` (single) | `text`, `vision-language`, `audio`, `video`, `multiple`, `n/a` |
| `language` (single) | `not-stated` (no language mentioned; abstracts rarely state English), `explicit-english`, `explicit-non-english` (one named language other than English), `explicit-multilingual` (two or more languages) |
| `languages_named` | languages named in the abstract |
| `coder` | `AI-first-pass` or `author` |

## Verification of the charting (scripts `07_verification_sample.ps1`, `08_agreement.ps1`)
A reproducible random sample (seed 94) of 20% of the charted studies is
recoded **independently** by one of the authors.

| file | content |
|---|---|
| `charting_verification_blind.csv` | sample records with title, abstract and empty coding columns; the first-pass codes are not shown |
| `charting_verification_key.csv` | first-pass codes for the same records, kept apart until the recoding is done |
| `charting_verification_merged.csv` | both codings side by side |
| `charting_agreement.csv` | per field: percent agreement and Cohen's kappa (single-label fields); exact-set agreement and mean Jaccard similarity (multi-label fields) |

## `data/processed/charting_summary.csv` (script `09_charting_summary.ps1`)
Counts per field and value: `field`, `value`, `n`, `denominator`, `percent`.
Multi-label fields count a study once per label. Denominators: all charted
studies for `study_type`, `source_kind`, `year`, `domain` and `language`;
studies that test models (`empirical-evaluation`, `mitigation`,
`mechanistic`) for `paradigm`; studies whose `model_families` is not `n/a`
for `model_families` and `modality`.
