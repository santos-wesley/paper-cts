<#
  08_agreement.ps1 - Agreement among the AI-assisted first-pass charting and the
  independent recodings of the verification sample (R1).

  Input : data/processed/charting_verification_key.csv     (first-pass codes)
          data/processed/charting_verification_coder1.csv  (recoding by coder 1)
          data/processed/charting_verification_coder2.csv  (recoding by coder 2)
  Output: data/processed/charting_verification_merged.csv  (the three codings side by side)
          data/processed/charting_agreement.csv            (one row per pair and field)
          data/processed/charting_agreement_labels.csv     (per-label kappa, multi-label fields)

  Both coders worked independently of each other and of the first pass, and
  both used AI assistance. Agreement therefore measures the consistency of
  AI-assisted coding, not a fully human validation.

  Single-label fields: percent agreement and Cohen's kappa.
  Multi-label fields (';'-separated): exact-set agreement, mean Jaccard
  similarity, and Cohen's kappa for each label treated as present/absent,
  averaged over the labels used at least 4 times across the two codings
  (rarer labels are reported but not averaged).
#>
$ErrorActionPreference = 'Stop'
# Note: PowerShell variable names are case-insensitive ($codA and $a are distinct on purpose).
$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'

$single = @('study_type', 'modality', 'language')
$multi  = @('paradigm', 'model_families', 'domain')

function Format-Num($x){ return ([double]$x).ToString([Globalization.CultureInfo]::InvariantCulture) }
function Read-Coding($file){
  $h = @{}
  foreach($r in Import-Csv -Encoding UTF8 (Join-Path $proc $file)){ $h[$r.rec_id] = $r }
  return $h
}
# Callers wrap the result in @(): PowerShell unrolls a one-element array returned by a function.
function Get-Set([string]$s){
  return @(($s -split ';') | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne '' } | Sort-Object -Unique)
}
function Get-Kappa($a, $b){
  $n = $a.Count; $agree = 0
  for($i = 0; $i -lt $n; $i++){ if($a[$i] -eq $b[$i]){ $agree++ } }
  $po = $agree / $n
  $pe = 0.0
  foreach($c in @(($a + $b) | Sort-Object -Unique)){
    $pa = @($a | Where-Object { $_ -eq $c }).Count / $n
    $pb = @($b | Where-Object { $_ -eq $c }).Count / $n
    $pe += $pa * $pb
  }
  $k = if($pe -lt 1){ ($po - $pe) / (1 - $pe) } else { 1.0 }
  return @($po, $k)
}

$codings = [ordered]@{
  'first-pass' = Read-Coding 'charting_verification_key.csv'
  'coder1'     = Read-Coding 'charting_verification_coder1.csv'
  'coder2'     = Read-Coding 'charting_verification_coder2.csv'
}
$ids = @($codings['first-pass'].Keys | Sort-Object)
foreach($name in $codings.Keys){
  $missing = @($ids | Where-Object { -not $codings[$name].ContainsKey($_) })
  if($missing.Count){ throw "$name lacks records: $($missing -join ', ')" }
}

# ---- merged file
$merged = foreach($id in $ids){
  $o = [ordered]@{ rec_id = $id }
  foreach($f in ($single + $multi)){ foreach($name in $codings.Keys){ $o["${f}_$name"] = [string]$codings[$name][$id].$f } }
  [pscustomobject]$o
}
$merged | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'charting_verification_merged.csv')

# ---- pairwise agreement
$names = @($codings.Keys)
$out = New-Object System.Collections.ArrayList
$lab = New-Object System.Collections.ArrayList
for($x = 0; $x -lt $names.Count; $x++){ for($y = $x + 1; $y -lt $names.Count; $y++){
  $codA = $codings[$names[$x]]; $codB = $codings[$names[$y]]; $pair = "$($names[$x]) vs $($names[$y])"
  foreach($f in $single){
    $a = @($ids | ForEach-Object { ([string]$codA[$_].$f).Trim().ToLower() })
    $b = @($ids | ForEach-Object { ([string]$codB[$_].$f).Trim().ToLower() })
    $pk = Get-Kappa $a $b
    [void]$out.Add([pscustomobject][ordered]@{ pair = $pair; field = $f; kind = 'single'; n = $ids.Count
      percent_agreement = (Format-Num ([math]::Round(100 * $pk[0], 1))); cohen_kappa = (Format-Num ([math]::Round($pk[1], 3)))
      mean_jaccard = ''; mean_label_kappa = ''; labels_averaged = '' })
  }
  foreach($f in $multi){
    $sa = @{}; $sb = @{}; $exact = 0; $jsum = 0.0; $labels = @()
    foreach($id in $ids){
      $p = @(Get-Set $codA[$id].$f); $q = @(Get-Set $codB[$id].$f); $sa[$id] = $p; $sb[$id] = $q
      $inter = @($p | Where-Object { $q -contains $_ }).Count
      $union = @(@($p) + @($q) | Sort-Object -Unique).Count
      $j = if($union -eq 0){ 1.0 } else { $inter / $union }
      if($j -eq 1.0){ $exact++ }
      $jsum += $j; $labels += $p; $labels += $q
    }
    $ksum = 0.0; $kn = 0
    foreach($l in @($labels | Sort-Object -Unique)){
      $a = @($ids | ForEach-Object { [int]($sa[$_] -contains $l) })
      $b = @($ids | ForEach-Object { [int]($sb[$_] -contains $l) })
      $uses = ($a | Measure-Object -Sum).Sum + ($b | Measure-Object -Sum).Sum
      $pk = Get-Kappa $a $b
      $avg = $uses -ge 4
      if($avg){ $ksum += $pk[1]; $kn++ }
      [void]$lab.Add([pscustomobject][ordered]@{ pair = $pair; field = $f; label = $l; uses = $uses
        percent_agreement = (Format-Num ([math]::Round(100 * $pk[0], 1))); cohen_kappa = (Format-Num ([math]::Round($pk[1], 3))); averaged = [string]$avg })
    }
    $mk = if($kn){ Format-Num ([math]::Round($ksum / $kn, 3)) } else { '' }
    [void]$out.Add([pscustomobject][ordered]@{ pair = $pair; field = $f; kind = 'multi'; n = $ids.Count
      percent_agreement = (Format-Num ([math]::Round(100 * $exact / $ids.Count, 1))); cohen_kappa = ''
      mean_jaccard = (Format-Num ([math]::Round($jsum / $ids.Count, 3))); mean_label_kappa = $mk; labels_averaged = $kn })
  }
}}
$out | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'charting_agreement.csv')
$lab | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'charting_agreement_labels.csv')
$out | Format-Table pair, field, percent_agreement, cohen_kappa, mean_jaccard, mean_label_kappa -AutoSize | Out-String | Write-Output
Write-Output "written: charting_verification_merged.csv, charting_agreement.csv, charting_agreement_labels.csv"
