<#
  04_ground.ps1 — Integrity check + grounding of the taxonomy in the corpus.

  (A) Verifies that the technical works cited in the paper actually exist in the
      retrieved corpus (by arXiv id or title), separating the sycophancy-specific
      anchors (expected IN the corpus) from RLHF/alignment background works
      (expected OUTSIDE it, since they are cited by citation-chaining).

  (B) Content-analysis of the included abstracts: counts, across the corpus, the
      terms that define each taxonomy category, with example titles — so that
      each empirical axis is grounded in concrete, real studies.

  Output: data/processed/grounding_report.txt and taxonomy_evidence.csv
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'
$pool = Get-Content -Raw -Encoding UTF8 (Join-Path $proc 'pooled_dedup.json') | ConvertFrom-Json
$out  = New-Object System.Collections.ArrayList

function AddLine($s){ [void]$out.Add($s); Write-Output $s }

# ---- (A) verify cited works against the corpus --------------------------------
AddLine "=== (A) CITED TECHNICAL WORKS vs. RETRIEVED CORPUS ==="
$anchors = @(
  @{key='sharma2023';  ax='2310.13548'; frag='towards understanding sycophancy'},
  @{key='perez2022';   ax='2212.09251'; frag='model-written evaluations'},
  @{key='wei2023';     ax='2308.03958'; frag='synthetic data reduces sycophancy'},
  @{key='denison2024'; ax='2406.10162'; frag='sycophancy to subterfuge'},
  @{key='laban2023';   ax='2311.08596'; frag='flipflop'},
  @{key='fanous2025';  ax='2502.08177'; frag='syceval'},
  @{key='cheng2025';   ax='2505.13995'; frag='social sycophancy'},
  @{key='rimsky2024';  ax='2312.06681'; frag='contrastive activation addition'}
)
$background = @(
  @{key='rafailov2023(DPO)';        ax='2305.18290'; frag='direct preference optimization'},
  @{key='ouyang2022(InstructGPT)';  ax='2203.02155'; frag='follow instructions with human feedback'},
  @{key='bai2022(ConstitutionalAI)';ax='2212.08073'; frag='constitutional ai'},
  @{key='skalse2022(rewardhacking)';ax='2209.13085'; frag='reward hacking'}
)
function Find-Rec($ax,$frag){
  $hit = $pool | Where-Object { $_.arxiv_id -eq $ax }
  if(-not $hit){ $hit = $pool | Where-Object { ([string]$_.title).ToLower().Contains($frag) } }
  return $hit | Select-Object -First 1
}
AddLine "-- sycophancy-specific anchors (expected IN corpus) --"
foreach($a in $anchors){ $r=Find-Rec $a.ax $a.frag; AddLine ("  [{0}] {1}  =>  {2}" -f ($(if($r){'FOUND'}else{'MISSING'})), $a.key, ($(if($r){$r.rec_id+' '+$r.title}else{'(not in corpus)'}))) }
AddLine "-- RLHF/alignment background (expected OUTSIDE corpus; cited by chaining) --"
foreach($a in $background){ $r=Find-Rec $a.ax $a.frag; AddLine ("  [{0}] {1}  =>  {2}" -f ($(if($r){'in-corpus'}else{'not-in-corpus'})), $a.key, ($(if($r){$r.rec_id}else{'(as expected, cited by chaining)'}))) }

# ---- (B) ground each taxonomy category in the abstracts -----------------------
AddLine ""
AddLine "=== (B) TAXONOMY CATEGORIES GROUNDED IN THE CORPUS (abstract content-analysis) ==="
$withAbs = $pool | Where-Object { -not [string]::IsNullOrWhiteSpace($_.abstract) }
AddLine ("records with abstract analysed: " + $withAbs.Count)
$terms = [ordered]@{
  'A Form: feedback sycophancy'      = 'feedback sycophan'
  'A Form: answer sycophancy'        = 'answer sycophan'
  'A Form: mimicry'                  = 'mimicry'
  'A Form: "are you sure?"/challenge'= 'are you sure|under (challenge|pressure|rebuttal)|challeng'
  'A Form: social / face'            = 'social sycophan|face-saving|face preserv| face '
  'B Trigger: RLHF / reward model'   = 'rlhf|reward model|human feedback|preference model'
  'B Trigger: user opinion/persona'  = 'persona|user.?s? (opinion|belief|view)|political'
  'C Object: opinion/factual/moral'  = 'factual|opinion|moral'
  'C Object: vision-language/multimodal' = 'vision-language|multimodal|vlm'
  'E Severity: mitigation'           = 'mitigat|reduce sycophan|reducing sycophan'
  'E Severity: harm/safety'          = 'harm|safety|delusion|mental health|psychosis'
  'E Severity: reward tampering'     = 'reward tampering|subterfuge'
  'F Temporal: multi-turn/longitudinal' = 'multi-turn|multi turn|longitudinal|conversation'
  'G Status: hallucination link'     = 'hallucinat'
  'G Status: truthfulness/honesty'   = 'truthful|honest|accuracy'
  'Method: benchmark/evaluation'     = 'benchmark|evaluat'
}
$rows = New-Object System.Collections.ArrayList
foreach($t in $terms.GetEnumerator()){
  $matched = @($withAbs | Where-Object { (([string]$_.title)+' '+([string]$_.abstract)).ToLower() -match $t.Value })
  $ex = ($matched | Select-Object -First 2 | ForEach-Object { $_.title }) -join ' | '
  AddLine ("  {0,-40} n={1,-4} e.g.: {2}" -f $t.Key, $matched.Count, $ex)
  [void]$rows.Add([pscustomobject]@{ category=$t.Key; regex=$t.Value; n_papers=$matched.Count; example_titles=$ex })
}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'taxonomy_evidence.csv')
$out -join "`r`n" | Set-Content -Encoding UTF8 (Join-Path $proc 'grounding_report.txt')
AddLine ""
AddLine "written: grounding_report.txt, taxonomy_evidence.csv"