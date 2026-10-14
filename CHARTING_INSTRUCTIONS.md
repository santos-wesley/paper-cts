# Charting instructions (abstract-level), scoping review on LLM sycophancy

You will code each study in your batch file. Each record shows `rec_id`, the
TITLE and the ABS (abstract). Code **only what the title and abstract state**.
Do not use outside knowledge of the paper, its authors or the field. When the
abstract is silent on a field, use `not-stated`. Never guess model names or
languages.

Output: a CSV file (UTF-8) with exactly this header and one row per record, in
the same order as the batch file, every field in double quotes:

"rec_id","study_type","paradigm","model_families","models_named","domain","modality","language","languages_named","notes"

Multi-label fields use `;` between values (no spaces), e.g. `openai;google`.
Use only the values listed below (lowercase, exactly as written).

## study_type (exactly one)
- `empirical-evaluation`: measures sycophancy in one or more models (benchmark, experiment, audit, case analysis of model outputs) without proposing a method to reduce it as its main contribution.
- `mitigation`: main contribution is a method to reduce sycophancy (training, prompting, steering, architecture, guardrail, protocol), with some test of it. If a method is proposed with no test at all, use `conceptual`.
- `mechanistic`: main contribution explains internal mechanisms (probing, circuits, sparse autoencoders, representations), even if it also shows a steering demo.
- `human-subjects`: studies people: experiments or surveys with participants, interviews, or analysis of user-generated reports about their experiences with sycophantic AI.
- `conceptual`: theoretical, philosophical, normative, position or argumentative paper; includes formal or mathematical models and proposals of frameworks or research agendas without an empirical test on LLM outputs.
- `review`: literature review, scoping or systematic review, survey of the literature.
- `protocol`: preregistration or study protocol with no results yet.
- `other`: none of the above (say why in notes).

## paradigm (one or more; only for empirical-evaluation, mitigation, mechanistic; otherwise `n/a`)
How sycophancy is elicited or measured in the models:
- `opinion-identity-cue`: the prompt states the user's opinion, belief, suggested answer, identity, persona or authority claim before the model answers.
- `challenge-rebuttal`: pressure against a position the model already gave or holds: doubt ("are you sure?"), rebuttal, insistence, repeated disagreement, multi-turn persuasion.
- `feedback-praise`: the model evaluates or praises work or answers attributed to the user.
- `false-premise-mimicry`: a false presupposition or user error is embedded in the prompt (not framed as the user's opinion) and the model may accept or repeat it.
- `social-face`: advice, validation of the user's actions or feelings, moral judgement of the user, face preservation, emotional or therapeutic support.
- `internal-probe`: internal activations are probed, steered or decomposed.
- `other`: a different elicitation (say which in notes).
- `not-stated`: the study tests models but the abstract does not say how.

## model_families (one or more)
`openai` (GPT, ChatGPT, o-series, Codex), `anthropic` (Claude), `google` (Gemini, Gemma, MedGemma, PaLM), `meta-llama` (Llama), `mistral` (Mistral, Mixtral), `qwen` (Qwen), `deepseek` (DeepSeek), `other` (any other named model or provider: Grok, Kimi, Doubao, Phi, Copilot, Perplexity, OLMo, etc.), `not-stated` (models are tested but not named), `n/a` (no model is tested, e.g. conceptual or review papers).

## models_named
The model names exactly as written in the abstract, separated by `;`. Empty if none.

## domain (one or more)
`general-factual`, `math-reasoning`, `code`, `medicine-health`, `mental-health`, `education`, `law`, `politics-opinion`, `advice-interpersonal` (personal advice, relationships, moral advice, AITA-type cases), `science`, `agents-memory` (agents, multi-agent systems, memory), `llm-as-judge`, `other` (e.g. finance, business, robotics, software requirements; say which in notes), `not-stated`.
For conceptual papers, code a domain only if the abstract focuses on one; otherwise `not-stated`.

## modality (exactly one)
`text`, `vision-language`, `audio`, `video`, `multiple`, `n/a` (no model tested). Use `text` when models are tested and nothing suggests another modality.

## language (exactly one) and languages_named
- `not-stated`: no language mentioned (most abstracts; do NOT assume English).
- `explicit-english`: the abstract says the evaluation is in English only.
- `explicit-non-english`: one named language other than English (e.g. Turkish, Bengali, Hindi).
- `explicit-multilingual`: two or more languages, or "N languages".
`languages_named`: the languages named, separated by `;` (empty if none).

## notes
Short, only when useful: why an uncertain code was chosen, or that the abstract is missing or is just a citation line (then code what the title supports and say so).

## Checks before you finish
- One row per record, same order, `rec_id` copied exactly.
- `paradigm` is `n/a` for conceptual, review, protocol and human-subjects rows.
- `model_families` and `modality` are `n/a` when no model is tested.
- No values outside the lists above.
