<#
  03_screen.ps1 — Deterministic, reproducible two-stage selection.

  Stage 1 — SCREENING (title + abstract), explicit lexical criteria:
     E2  excluded : sycophancy stem "sycophan" not present (off-target match)
     E1  excluded : sycophancy present but NO AI/LLM cue
                    (human/organisational/political/literary sycophancy, no AI link)
  Stage 2 — ELIGIBILITY (centrality of the concept, assessed from metadata):
     E3  excluded : sycophancy is only mentioned (not in the title) -> not the
                    central concern of the work
     INCLUDED     : sycophancy in the TITLE and an AI/LLM cue present
                    (studies centrally concerning sycophancy in LLMs / AI)

  Every decision is written to data/processed/screening_decisions.csv, and the
  final included set to data/processed/included_studies.csv. Fully re-runnable.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'
$recs = Get-Content -Raw -Encoding UTF8 (Join-Path $proc 'pooled_dedup.json') | ConvertFrom-Json

$aiCues = @('language model','llm','large language model','chatbot','chatgpt','gpt-','gpt ',
  'rlhf','reinforcement learning from human feedback','artificial intelligence',' ai ','ai-',
  'generative','transformer','neural network','dialogue system','conversational',
  'alignment','reward model','instruction tun','fine-tun','foundation model',
  'hallucinat','llms','claude','gemini','llama','deep learning','machine learning',
  'nlp','natural language processing','prompt','vision-language','multimodal')

$rows = foreach($r in $recs){
  $title = ([string]$r.title).ToLower()
  $hay   = ($title + ' ' + ([string]$r.abstract).ToLower())
  $hasSyco  = $hay   -match 'sycophan'
  $sycoTitle= $title -match 'sycophan'
  $hasAI = $false; foreach($c in $aiCues){ if($hay.Contains($c)){ $hasAI=$true; break } }

  if(-not $hasSyco){ $dec='exclude'; $stage='screening'; $reason='E2 not-sycophancy' }
  elseif(-not $hasAI){ $dec='exclude'; $stage='screening'; $reason='E1 not-AI/LLM' }
  elseif(-not $sycoTitle){ $dec='exclude'; $stage='eligibility'; $reason='E3 sycophancy-not-central' }
  else { $dec='include'; $stage='included'; $reason='' }

  [pscustomobject]@{ rec_id=$r.rec_id; year=$r.year; sources=($r.sources -join '+');
    has_abstract=([bool](-not [string]::IsNullOrWhiteSpace($r.abstract)));
    decision=$dec; stage=$stage; reason=$reason; title=$r.title }
}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'screening_decisions.csv')

$screened   = $rows.Count
$exScreen   = @($rows | Where-Object stage -eq 'screening').Count
$e1 = @($rows | Where-Object reason -match 'E1').Count
$e2 = @($rows | Where-Object reason -match 'E2').Count
$eligAssessed = $screened - $exScreen
$e3 = @($rows | Where-Object reason -match 'E3').Count
$inc = @($rows | Where-Object decision -eq 'include')

Write-Output ("Records screened (title/abstract): " + $screened)
Write-Output ("  excluded at screening: " + $exScreen + "  (E1 not-AI/LLM=" + $e1 + "; E2 not-sycophancy=" + $e2 + ")")
Write-Output ("Assessed for eligibility: " + $eligAssessed)
Write-Output ("  excluded at eligibility (E3 sycophancy not central): " + $e3)
Write-Output ("INCLUDED: " + $inc.Count)
Write-Output ("  included with abstract: " + (@($inc | Where-Object has_abstract).Count) + " ; title-only: " + (@($inc | Where-Object { -not $_.has_abstract }).Count))

$incIds = $inc.rec_id
$recs | Where-Object { $_.rec_id -in $incIds } |
  ForEach-Object { [pscustomobject]@{ rec_id=$_.rec_id; year=$_.year; title=$_.title; doi=$_.doi; arxiv_id=$_.arxiv_id; sources=($_.sources -join '+'); url=$_.url } } |
  Sort-Object year -Descending | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'included_studies.csv')

# machine-readable PRISMA summary for the paper/repo
[ordered]@{
  identification = [ordered]@{ arXiv=272; OpenAlex=487; SemanticScholar=364; total=1123 }
  duplicates_removed = 577
  records_screened = $screened
  excluded_screening = [ordered]@{ total=$exScreen; E1_not_AI=$e1; E2_not_sycophancy=$e2 }
  assessed_eligibility = $eligAssessed
  excluded_eligibility = [ordered]@{ total=$e3; E3_not_central=$e3 }
  included = $inc.Count
} | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $proc 'prisma_counts.json')
Write-Output "written: screening_decisions.csv, included_studies.csv, prisma_counts.json"