<#
  09_charting_summary.ps1 - Descriptive profile of the charted corpus (R1).

  Reads data/processed/charting.csv and eligible_studies.csv and counts, per
  field, how many studies carry each value. Multi-label fields count a study
  once per label, so their percentages can sum to more than 100%.
  Denominators:
    - study_type, domain, language, source_kind, year: all charted studies
    - paradigm: studies that test models (empirical-evaluation, mitigation,
      mechanistic)
    - model_families, modality: studies whose model_families is not n/a

  Output: data/processed/charting_summary.csv (field, value, n, denominator, percent)
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'
$chart = @(Import-Csv -Encoding UTF8 (Join-Path $proc 'charting.csv'))
$elig = @{}
foreach($e in Import-Csv -Encoding UTF8 (Join-Path $proc 'eligible_studies.csv')){ $elig[$e.rec_id] = $e }

$testing = @('empirical-evaluation','mitigation','mechanistic')
$out = New-Object System.Collections.ArrayList

function Add-Counts($field, $rows, $getter, [switch]$multi){
  $den = $rows.Count
  $counts = @{}
  foreach($r in $rows){
    $raw = [string](& $getter $r)
    $vals = if($multi){ @($raw -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | Sort-Object -Unique) } else { @($raw.Trim()) }
    foreach($v in $vals){ if($counts.ContainsKey($v)){ $counts[$v]++ } else { $counts[$v] = 1 } }
  }
  foreach($k in ($counts.Keys | Sort-Object { -$counts[$_] }, { $_ })){
    $pct = if($den -gt 0){ [math]::Round(100 * $counts[$k] / $den, 1) } else { 0 }
    # invariant culture: decimal point regardless of the machine's regional settings
    $pctTxt = ([double]$pct).ToString([Globalization.CultureInfo]::InvariantCulture)
    [void]$out.Add([pscustomobject][ordered]@{ field=$field; value=$k; n=$counts[$k]; denominator=$den; percent=$pctTxt })
  }
}

Add-Counts 'study_type' $chart { param($r) $r.study_type }
Add-Counts 'source_kind' $chart { param($r) $elig[$r.rec_id].source_kind }
Add-Counts 'year' $chart { param($r) $elig[$r.rec_id].year }
Add-Counts 'domain' $chart { param($r) $r.domain } -multi
Add-Counts 'language' $chart { param($r) $r.language }
$tested = @($chart | Where-Object { $testing -contains $_.study_type })
Add-Counts 'paradigm' $tested { param($r) $r.paradigm } -multi
$withModels = @($chart | Where-Object { $_.model_families -ne 'n/a' })
Add-Counts 'model_families' $withModels { param($r) $r.model_families } -multi
Add-Counts 'modality' $withModels { param($r) $r.modality }

$out | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'charting_summary.csv')
$out | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
Write-Output ("Charted studies: {0}; testing models: {1}; with named or unnamed models: {2}" -f $chart.Count, $tested.Count, $withModels.Count)
Write-Output "written: charting_summary.csv"
