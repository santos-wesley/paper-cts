# Participation charting instructions (full text), scoping review on LLM sycophancy

This second charting pass (revision R1) records **who takes part** in the
research on LLM sycophancy, in four positions: who writes it (author
affiliations), who is tested (the user identities simulated in prompts), in
which language the models are evaluated, and whose judgement defines the
reference against which a response counts as sycophantic. It complements the
abstract-level charting in `CHARTING_INSTRUCTIONS.md` and uses the **full text**
of each study, because affiliations and the profile of human participants are
rarely given in abstracts.

You will code each study in your batch file. Each record gives `rec_id`, the
title, the `study_type` and `paradigm` from the first charting pass, and the
paths to two text files extracted from the PDF: the first two pages (`p12`,
where the author block usually is) and the full text (`full`). If no text file
is available, the record gives the study's DOI link and its abstract: open the
DOI link once, read the author block and whatever the landing page shows, write
`landing` in `fulltext`, and code the other fields from the landing page and the
abstract (most will be `not-stated`). If the landing page cannot be opened,
write `no` in `fulltext`, `no-fulltext` in `author_countries`, and code the
other fields from the abstract only.

Rules that apply to every field:
- Code only what the paper states. Do not use outside knowledge of the authors.
- **Never infer anyone's race, ethnicity or gender from names, photos or
  affiliations.** Race enters this charting only through what the study itself
  manipulates (identity cues) or reports (participant demographics).
- Do not open other sources (apart from the DOI link of a study without full
  text), and do not look at any metadata file in the repository: the
  affiliations recorded by OpenAlex and Zenodo are kept apart to validate this
  charting.
- When the paper is silent, use `not-stated`.

Output: a CSV file (UTF-8) with exactly this header and one row per record, in
the same order as the batch file, every field in double quotes:

"rec_id","fulltext","author_countries","affiliation_evidence","identity_cues","race_categories","human_data","human_origin","human_race_reported","baseline_source","baseline_population","languages_evaluated","notes"

Multi-label fields use `;` between values (no spaces). Use only the values
listed below (lowercase, exactly as written), except where free text is asked.

## fulltext (exactly one)
`yes` (a full-text file was available and read), `landing` (only the DOI
landing page was available) or `no`.

## author_countries
The distinct countries of all author affiliations, as ISO 3166-1 alpha-2 codes
in upper case, sorted and separated by `;` (e.g. `BR;US`).
- Take the country from the affiliation line. If the line names a university or
  research institute without a country, use the country where that institution
  is located when it is unambiguous (e.g. "Stanford University" is `US`,
  "Universidade de Sao Paulo" is `BR`).
- Multinational companies (Google, Microsoft, Meta, Amazon, IBM, Anthropic,
  OpenAI, etc.): use the location the paper states; if none, use the country of
  the company's headquarters and write `hq` in notes.
- Independent researchers: use the country if the paper states one.
- If no author has a determinable country: `not-stated`. If neither the text
  nor the landing page was available: `no-fulltext`.

## affiliation_evidence
Short verbatim copy of the affiliation line(s) you used (at most 250
characters; shorten long lists with `...`). Empty only if `not-stated`.

## identity_cues (one or more)
User or persona attributes that the study **manipulates or simulates** in the
prompts or conversations sent to the models (e.g. "As a Black woman, I think...",
persona descriptions, demographic profiles):
`race-ethnicity`, `gender`, `age`, `nationality-region`, `religion`,
`language-dialect`, `political`, `socioeconomic`, `education-expertise`
(credentials, profession, authority or expertise claims), `disability-health`,
`sexuality`, `other` (say which in notes), `none` (the study tests models but
simulates no user identity), `n/a` (no model is tested).
- A stated opinion or belief alone is not an identity cue.
- Attributes of third parties in a task (e.g. the race of a job candidate in a
  hiring vignette) are not user identity cues: code `none` and say so in notes.

## race_categories
If `race-ethnicity` is coded: the racial or ethnic categories the study uses,
verbatim, separated by `;` (e.g. `Black;White;Asian;Hispanic`). Otherwise empty.

## human_data (one or more)
Human judgements or data, other than the authors' own, that the study relies on:
`participants` (subjects of an experiment, survey or interview), `annotators`
(paid or volunteer labelers, raters, crowdworkers who label or rate outputs),
`experts` (domain experts who judge outputs), `online-community` (posts or
comments from forums or platforms used as data or as a reference, e.g. Reddit),
`none`.

## human_origin
Where those humans are from, as stated: ISO codes separated by `;`, or a short
free text when the paper gives only a platform or a region (e.g.
`Prolific: US;GB`, `MTurk (US-based workers)`, `r/AmITheAsshole`).
`not-stated` if the paper does not say; `n/a` if `human_data` is `none`.

## human_race_reported (exactly one)
`yes` if the paper reports the racial or ethnic composition of its human
participants or annotators; `no` if it has such humans but does not report it;
`n/a` if `human_data` is `none` or only `online-community`.

## baseline_source (one or more)
What defines the appropriate (non-sycophantic) response against which model
outputs are judged:
`ground-truth` (an answer key or verifiable fact), `counterfactual` (the same
item without the user cue, or the model's own earlier answer), `human-consensus`
(majority of crowdworkers, annotators or an online community), `expert-judgment`,
`llm-judge` (another model decides), `authors-rubric` (criteria written by the
authors), `other` (say which in notes), `not-stated`, `n/a` (no model is
tested).

## baseline_population
When `human-consensus` or `expert-judgment` is coded: who those humans are, as
stated (e.g. `r/AmITheAsshole top-voted comments`, `US crowdworkers`,
`licensed clinicians`). Otherwise empty.

## languages_evaluated
The languages of the prompts or of the evaluation, as stated in the full text,
separated by `;` (e.g. `English;Portuguese`). `not-stated` if the paper never
says (do NOT assume English, even if the prompts shown are in English; in that
case write `not-stated` and add `examples-in-English` in notes). `n/a` if no
model is tested.

## notes
Short: uncertain choices, `hq` for headquarters-based countries,
`examples-in-English`, third-party attributes, or anything a second coder would
need to reproduce your decision.

## Checks before you finish
- One row per record, same order, `rec_id` copied exactly.
- `identity_cues`, `baseline_source` and `languages_evaluated` are `n/a` for
  conceptual, review and protocol studies that test no model.
- `race_categories` is filled if and only if `race-ethnicity` is coded.
- No race, ethnicity or gender was inferred from names, photos or affiliations.

## Decisions taken during coding (recorded after the pass)
Cases the rules above did not anticipate, decided the same way in all batches:
- AI systems listed as co-authors are not authors for `author_countries`.
- "Google DeepMind" without a stated location is coded `GB` (London headquarters).
- Conference venues printed on the first page (e.g. "AISTATS 2026, Tangier, Morocco") are not affiliations.
- For studies coded only from the DOI landing page or the abstract, a silent field is `not-stated`, including `identity_cues`, `human_data` and `human_race_reported`.
- In human-subjects studies where the chatbot is only the stimulus shown to people, `identity_cues`, `baseline_source` and `languages_evaluated` are `n/a`.
- Expertise or authority attributed to a third party ("A Stanford professor suggests...") is not a user identity cue (`none`, with a note); expertise the user claims ("I have a PhD") is `education-expertise`.
- A change of prompt language or cultural framing alone is not a user identity cue.

## Verification by the authors
- Author countries were compared with the affiliation countries recorded by OpenAlex, which the coders did not see (`participation_validation.csv`).
- The first two pages of every retrieved full text were searched for African and Latin American place names, and every full text for phrasing that simulates a user's race (e.g. "as a Black woman", "Hispanic persona"). This confirmed the absence of African affiliations and that a single study manipulates the user's race, and found one missed affiliation (R0370, corrected).
