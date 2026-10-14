<#
  07_verification_sample.ps1 - Draws the random verification sample (R1).

  Reads data/processed/charting.csv (AI-assisted first-pass charting) and draws
  a reproducible random sample (seed 94) of 20% of the charted studies.

  Writes two files:
    charting_verification_blind.csv  - what the author recodes: rec_id, title,
        abstract and EMPTY coding columns. The first-pass codes are NOT shown,
        so that the recoding is independent.
    charting_verification_key.csv    - the first-pass codes for the same
        records, kept apart until the author has finished.

  After the author fills in the blind file, 08_agreement.ps1 merges both and
  computes agreement.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'
$rows = @(Import-Csv -Encoding UTF8 (Join-Path $proc 'charting.csv'))
$elig = @{}
foreach($e in Import-Csv -Encoding UTF8 (Join-Path $proc 'eligible_studies.csv')){ $elig[$e.rec_id] = $e }

$k = [math]::Ceiling(0.20 * $rows.Count)
$null = Get-Random -SetSeed 94
$sample = @($rows | Sort-Object rec_id | Get-Random -Count $k | Sort-Object rec_id)

$fields = @('study_type','paradigm','model_families','domain','modality','language')
$blind = foreach($r in $sample){
  $o = [ordered]@{ rec_id = $r.rec_id; title = $elig[$r.rec_id].title; abstract = $elig[$r.rec_id].abstract }
  foreach($f in $fields){ $o[$f] = '' }
  $o['notes'] = ''
  [pscustomobject]$o
}
$key = foreach($r in $sample){
  $o = [ordered]@{ rec_id = $r.rec_id }
  foreach($f in $fields){ $o[$f] = $r.$f }
  [pscustomobject]$o
}
$blind | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'charting_verification_blind.csv')
$key   | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'charting_verification_key.csv')
Write-Output ("Charted studies: {0}; verification sample (20%, seed 94): {1}" -f $rows.Count, $k)
Write-Output "written: charting_verification_blind.csv, charting_verification_key.csv"
