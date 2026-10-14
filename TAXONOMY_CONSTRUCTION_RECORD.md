# Taxonomy Construction Record

**Supplementary material for the manuscript** *Algorithmic Cordiality: Sycophancy in Language Models as a Sociotechnical Problem* (under double-blind review; authors anonymized).

This document records how the manuscript's seven-axis taxonomy of sycophancy was constructed with the systematic method of Nickerson, Varshney and Muntermann (2013), as refined by Kundisch et al. (2022). It compiles the construction path documented in the original study underlying the manuscript. Nothing in this record is illustrative: the corpus counts reported in Section 3 below are the real output of the executed systematic search (8 July 2026) archived in this repository.

---

## 1. Method and meta-characteristic

The method of Nickerson, Varshney and Muntermann (NVM) supplies a procedure and stopping rules for taxonomy development, raising it above intuitive typologizing. It begins by fixing a **meta-characteristic**: the single overarching attribute, derived from the taxonomy's normative purpose, of which every dimension must be a logical instance.

**Meta-characteristic adopted:** the relational configuration of *pleasing agreement* — what elicits it, what it bears on, the surface form it takes, the social function it performs, its temporal pattern, and its epistemic-normative cost.

This choice enforces the manuscript's organizing hypothesis at the level of method: any candidate dimension that does not articulate some aspect of the substitution of a criterion of correctness by a criterion of pleasing is excluded by construction.

**Domain declaration:** the taxonomy classifies the full continuum of pleasing agreement, from the legitimate degree zero to the harmful; it is not restricted to the pathological region, which the manuscript's Table 2 demarcates from neighbouring concepts.

## 2. Iteration modes

The method proceeds iteratively, alternating two modes, with the ending conditions of Section 4 checked at the end of each pass; iteration halted only when all conditions held.

**Empirical-to-conceptual (E2C):** measurable subtypes reported in the technical literature were coded and grouped into candidate dimensions. Sources coded in this mode include the measured subtype scheme of Sharma et al. (2023); the reward-tampering escalation documented by Denison et al. (2024); social/face-preservation sycophancy (Cheng et al., 2025); implicit rhetorical sycophancy and paltering (Liang et al., 2025); conversational-pressure dynamics (Laban et al., 2023); and the user-cue probes of Perez et al. (2022).

**Conceptual-to-empirical (C2E):** dimensions were deduced from theory in advance of the data: the recognition/objectification axis from Honneth (1995) and Giacomini (2021); the truth-condition/approval-condition axis from Chateaubriand (2001) and Frankfurt (2005); the communicability axis from de Souza (2005); and the horizon-of-expectations axis from Jauss (1982).

In the E2C mode, the subtypes reported by the anchor studies listed above were grouped according to the four questions that also structure the meta-characteristic: what triggers the agreement, what is its object, what form it takes, and what its epistemic and relational cost is. The presence of the resulting categories in the wider corpus was then checked lexically (Section 3). The field-by-field charting of every eligible study was added in revision R1 (see `CODEBOOK.md`, "Revision R1 additions", and revision note 4 below).

## 3. Derivation and grounding of each axis

The empirical axes (A, B, C, F) are E2C: derived chiefly from the subtype schemes of identifiable technical studies. Most of these studies are in the retrieved corpus; Perez et al. (2022) is outside the included set because "sycophancy" is not in its title, and Laban et al. (2023) was not retrieved; both entered by citation chaining. The presence of the categories in the corpus was then checked by an exploratory lexical pass over 339 abstracts (see `data/processed/taxonomy_evidence.csv` and `data/processed/grounding_report.txt`). This check is indicative rather than confirmatory: lexical matching misses categories that abstracts name differently (the feedback and answer forms returned n = 0) and admits false positives. The normative and social axes (D, E, G) are C2E: derived from the theoretical canon incorporated by purposive sampling. The distinction is stated so that no axis is presented as data-derived that is in fact theory-derived, or the reverse.

| Axis | Mode | Anchoring | Lexical check in the corpus (indicative; records matching the category terms) |
|---|---|---|---|
| A. Form (surface) | E2C | Subtype scheme of Sharma et al. (2023): feedback, answer, mimicry; social/face-preservation (Cheng et al., 2025); implicit rhetorical/paltering (Liang et al., 2025) | social/face n = 17; challenge-under-pressure forms n = 63; feedback n = 0 and answer n = 0 (named differently in abstracts) |
| B. Trigger (cause) | E2C | Reward-model preference and annotator bias (Sharma et al., 2023); explicit user cue (Perez et al., 2022); conversational pressure (Laban et al., 2023); engagement design (Zuboff, 2019; OpenAI, 2025) | user opinion/persona n = 74 |
| C. Object | E2C | Opinion, empirical fact, moral value, identity/face (Cheng et al., 2025), artefact quality | opinion/factual/moral n = 75; vision-language/multimodal n = 28 |
| D. Social function | C2E | Ritual deference (Goffman, 1967); ingratiation (classical *kolax*); emotional labour (Hochschild, 1983); gift-to-dependence (Mauss); pseudo-recognition (Honneth, 1995; Giacomini, 2021) | theory-derived; see Section 5, revision note 1 |
| E. Severity | C2E (gradient) | From legitimate agreement (degree zero) through progressive and mildly regressive to epistemically corrosive and harmful | harm/safety n = 114; mitigation n = 107 (corpus support for the corrosive/harmful poles) |
| F. Temporality | E2C | Immediate/proactive; reactive under challenge; relational/longitudinal | multi-turn/longitudinal n = 64 |
| G. Normative-dialogical status | C2E | Violation of sincerity and of accuracy (Williams, 2002; Frankfurt, 2005; Grice, 1975); corrupted epistemic route (Fricker, 2007); banking anti-dialogue (Freire, 1970); locus of imputation | theory-derived |

Additional grounding counts from the evidence table: benchmarking/evaluation methods n = 212; truthfulness/honesty status n = 93; hallucination link n = 52; reward tampering n = 1.

**Integrity check.** The sycophancy-specific works cited as empirical anchors were verified to be present in the retrieved, deduplicated corpus of 546 records: Sharma et al. (2023), Perez et al. (2022), Wei et al. (2023), Denison et al. (2024), Fanous et al. (2025), and Cheng et al. (2025). All except Perez et al. (2022) are also in the included set. Works cited for general RLHF background are outside the sycophancy-specific corpus and were incorporated by citation-chaining, as stated in the manuscript's methodology.

## 4. Ending conditions and how they were checked

**Objective conditions (NVM):**

1. *Collective exhaustiveness* — every studied object classifiable. Checked against the grounding pass: the corpus categories of the evidence table map onto the axes without remainder.
2. *Mutual distinctness* — each dimension's characteristics mutually distinct, no dimension duplicating another. Supported by the decision rules stated in the manuscript (e.g., the observable marker separating particularistic indulgence from ingratiation on axis D) and by the two-mechanism distinction (user-indexed pleasing vs. distributional default) that keeps axis B's causal categories apart.

**Subjective conditions (NVM):**

3. *Conciseness* — seven axes.
4. *Robustness* — categories differentiate the corpus's observed subtypes.
5. *Comprehensiveness* — covers surface form through normative status.
6. *Extensibility* — new subtypes are addable within existing axes (e.g., multimodal sycophancy extends C without a new axis).
7. *Explanatory power* — the composite signature (a simultaneous coordinate on all seven axes) discriminates cases that single labels conflate.

## 5. Classification-theoretic design decisions

1. Following Bailey (1994), the scheme distinguishes typology (conceptual, deductive) from taxonomy (empirical, often inductive) and monothetic from polythetic classification. The scheme is deliberately hybrid: axes A, C and F are **polythetic** (family resemblance suffices); the categories of D and G are **Weberian ideal types**, deliberately one-sided accentuations against which real cases are measured.
2. The construction is an exercise in conceptual engineering and amelioration (Haslanger, 2012) in the spirit of Carnapian explication (Carnap, 1950): the working definition is an explicatum meeting the criteria of similarity, exactness, fruitfulness and simplicity, not a report of ordinary usage.
3. Sycophancy is conceded to be a potentially essentially contested concept (Gallie, 1956); the taxonomy aims at fruitful ordering rather than at closing the contest.
4. The whole inference is abductive (Timmermans; Tavory, 2012): the scheme is proposed as a best available explanation of the assembled anomalies, held open to revision as new subtypes appear.

## 6. Revision notes (article version)

1. **Axis D category renamed.** The category originally labelled "algorithmic cordiality" was renamed **"particularistic indulgence (jeitinho)"** in the article version, to keep genus and species distinct: algorithmic cordiality names the operation as a whole, while the axis-D category names one social function it can perform. A decision rule was added (the category is assigned when the output bends an impersonal standard to fit the particular interlocutor; ingratiation courts favour without bending any standard).
2. **Meta-characteristic restated.** The original compact statement ("the trigger, object, form, and epistemic-relational cost of pleasing agreement") was restated to make all seven facets explicit (elicitation, object, surface form, social function, temporal pattern, epistemic-normative cost), so that axes D, F and G are visibly generated by it.
3. **Domain declared.** The article states explicitly that the classified domain is the continuum of pleasing agreement including the legitimate degree zero (see Section 1 above).
4. **Corpus grounding restated (revision R1).** An earlier version of this record described the E2C step as a thematic content analysis of every source in the corpus, and the empirical axes as anchored in the 247 included studies. Both descriptions said more than the deposited data support: the categories were derived from the anchor studies and checked lexically in the corpus. Sections 2 and 3 were corrected accordingly, and a field-by-field charting of all eligible studies was added (`CODEBOOK.md`, "Revision R1 additions").

## 7. Files in this repository

See `MANIFEST.md` for the full inventory (scripts in `scripts/`, raw and processed data in `data/`, PRISMA-ScR reporting in `PRISMA.md`, coding scheme in `CODEBOOK.md`, execution environment in `ENVIRONMENT.md`). Re-running the scripts reproduces the selection flow reported in the manuscript (1,123 identified; 577 duplicates removed; 88 excluded at screening; 211 at eligibility; 247 included); counts may drift slightly as the databases grow. The archived, citable deposit of this material (DOI withheld for blind review) will be referenced in the final version of the manuscript.

## References for this record

Bailey (1994) *Typologies and Taxonomies*; Carnap (1950) *Logical Foundations of Probability*; Chateaubriand (2001) *Logical Forms I*; Cheng et al. (2025) ELEPHANT, arXiv:2505.13995; Denison et al. (2024) arXiv:2406.10162; Fanous et al. (2025) SycEval; Frankfurt (2005) *On Bullshit*; Freire (1970) *Pedagogy of the Oppressed*; Fricker (2007) *Epistemic Injustice*; Gallie (1956) "Essentially Contested Concepts"; Giacomini (2021) *Profissão mulata*; Goffman (1967) *Interaction Ritual*; Grice (1975) "Logic and Conversation"; Haslanger (2012) *Resisting Reality*; Hochschild (1983) *The Managed Heart*; Honneth (1995) *The Struggle for Recognition*; Jauss (1982) *Toward an Aesthetic of Reception*; Kundisch et al. (2022) "An Update for Taxonomy Designers," *Business & Information Systems Engineering*; Laban et al. (2023); Liang et al. (2025); Mauss (2002 [1925]) *The Gift*; Nickerson, Varshney and Muntermann (2013) *EJIS* 22(3); OpenAI (2025) "Sycophancy in GPT-4o"; Perez et al. (2022) arXiv:2212.09251; Sharma et al. (2023) arXiv:2310.13548; de Souza (2005) *The Semiotic Engineering of Human-Computer Interaction*; Timmermans and Tavory (2012) *Sociological Theory* 30(3); Wei et al. (2023) arXiv:2308.03958; Williams (2002) *Truth and Truthfulness*; Zuboff (2019) *The Age of Surveillance Capitalism*.
