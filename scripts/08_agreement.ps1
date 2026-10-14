<#
  08_agreement.ps1 - Agreement between the AI-assisted first-pass charting and
  the author's independent recoding of a random verification sample (R1).

  Input : data/processed/charting_verification_blind.csv (filled in by the author)
          data/processed/charting_verification_key.csv   (first-pass codes)
  Output: data/processed/charting_verification_merged.csv (both codings side by side)
          data/processed/charting_agreement.csv           (one row per field)

  Single-label fields: percent agreement and Cohen's kappa.
  Multi-label fields (';'-separated): exact-set agreement and mean Jaccard
  similarity of the label sets.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'

$single = @('study_type','modality','language')
$multi  = @('paradigm','model_families','domain')

$blind = @(Import-Csv -Encoding UTF8 (Join-Path $proc 'charting_verification_blind.csv'))
$key = @{}
foreach($k in Import-Csv -Encoding UTF8 (Join-Path $proc 'charting_verification_key.csv')){ $key[$k.rec_id] = $k }
$rows = foreach($b in $blind){
  $o = [ordered]@{ rec_id = $b.rec_id }
  foreach($f in ($single + $multi)){ $o["${f}_ai"] = [string]$key[$b.rec_id].$f; $o["${f}_author"] = [string]$b.$f }
  [pscustomobject]$o
}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'charting_verification_merged.csv')

function Get-Set([string]$s){
  return @(($s -split ';') | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne '' } | Sort-Object -Unique)
}

$out = New-Object System.Collections.ArrayList
foreach($f in $single){
  $pairs = @($rows | Where-Object { $_."${f}_author" -ne '' })
  $n = $pairs.Count
  if($n -eq 0){ continue }
  $agree = @($pairs | Where-Object { $_."${f}_ai".Trim().ToLower() -eq $_."${f}_author".Trim().ToLower() }).Count
  $po = $agree / $n
  $cats = @($pairs | ForEach-Object { $_."${f}_ai".Trim().ToLower(); $_."${f}_author".Trim().ToLower() } | Sort-Object -Unique)
  $pe = 0.0
  foreach($c in $cats){
    $pa = @($pairs | Where-Object { $_."${f}_ai".Trim().ToLower() -eq $c }).Count / $n
    $pb = @($pairs | Where-Object { $_."${f}_author".Trim().ToLower() -eq $c }).Count / $n
    $pe += $pa * $pb
  }
  $kappa = if($pe -lt 1){ ($po - $pe) / (1 - $pe) } else { 1.0 }
  [void]$out.Add([pscustomobject][ordered]@{ field=$f; kind='single'; n=$n
    percent_agreement=[math]::Round(100*$po,1); cohen_kappa=[math]::Round($kappa,3); mean_jaccard='' })
}
foreach($f in $multi){
  $pairs = @($rows | Where-Object { $_."${f}_author" -ne '' })
  $n = $pairs.Count
  if($n -eq 0){ continue }
  $exact = 0; $jsum = 0.0
  foreach($p in $pairs){
    $a = Get-Set $p."${f}_ai"; $b = Get-Set $p."${f}_author"
    $inter = @($a | Where-Object { $b -contains $_ }).Count
    $union = @(($a + $b) | Sort-Object -Unique).Count
    if($union -eq 0){ $j = 1.0 } else { $j = $inter / $union }
    if($j -eq 1.0){ $exact++ }
    $jsum += $j
  }
  [void]$out.Add([pscustomobject][ordered]@{ field=$f; kind='multi'; n=$n
    percent_agreement=[math]::Round(100*$exact/$n,1); cohen_kappa=''; mean_jaccard=[math]::Round($jsum/$n,3) })
}
$out | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'charting_agreement.csv')
$out | Format-Table -AutoSize | Out-String | Write-Output
Write-Output "written: charting_agreement.csv"
