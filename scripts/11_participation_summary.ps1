<#
  11_participation_summary.ps1 - Summary and validation of the participation
  charting (revision R1).

  Input : data/processed/participation.csv          (full-text charting, see PARTICIPATION_INSTRUCTIONS.md)
          data/processed/charting.csv               (study_type, from the abstract-level charting)
          data/processed/metadata_affiliations.csv  (OpenAlex countries, from 10_fulltext.ps1)
  Output: data/processed/participation_summary.csv  (field, value, n, denominator, percent)
          data/processed/participation_validation.csv (author countries: charting vs OpenAlex)

  Regions follow the UN M49 standard (Americas split into Northern America and
  Latin America and the Caribbean; Cyprus and Turkey in Asia, as in M49).
  Unknown country codes stop the script, so the table below must be extended
  rather than silently ignored.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'

function Format-Num($x){ return ([double]$x).ToString([Globalization.CultureInfo]::InvariantCulture) }
# Callers wrap the result in @(): PowerShell unrolls a one-element array returned by a function into a scalar.
function Get-Set([string]$s){
  return @(($s -split ';') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | Sort-Object -Unique)
}

$regionCodes = @{
  'Northern America' = 'US CA BM GL PM'
  'Latin America and the Caribbean' = 'AR BO BR CL CO EC GY PY PE SR UY VE MX GT BZ SV HN NI CR PA CU DO HT JM TT BS BB PR GD LC VC AG DM KN'
  'Europe' = 'GB IE FR DE NL BE LU CH AT IT ES PT GR DK SE NO FI IS PL CZ SK HU RO BG HR SI RS BA ME MK AL EE LV LT UA BY MD RU MT LI MC AD SM VA XK'
  'Asia' = 'CN HK MO TW JP KR KP MN IN PK BD LK NP BT MV AF IR IQ SA AE QA KW BH OM YE JO LB SY IL PS TR CY AM AZ GE KZ UZ TM KG TJ TH VN KH LA MM MY SG ID PH BN TL'
  'Africa' = 'DZ EG LY MA TN SD SS NG GH CI SN ML BF NE TG BJ GM GN GW SL LR CV MR ET ER DJ SO KE UG TZ RW BI CD CG CM CF TD GA GQ ST AO ZM ZW MW MZ NA BW ZA LS SZ MG MU SC KM'
  'Oceania' = 'AU NZ FJ PG SB VU WS TO KI FM MH PW NR TV'
}
$region = @{}
foreach($k in $regionCodes.Keys){ foreach($c in ($regionCodes[$k] -split ' ')){ $region[$c] = $k } }

$part = @(Import-Csv -Encoding UTF8 (Join-Path $proc 'participation.csv'))
$type = @{}
foreach($c in Import-Csv -Encoding UTF8 (Join-Path $proc 'charting.csv')){ $type[$c.rec_id] = $c.study_type }
$meta = @{}
foreach($m in Import-Csv -Encoding UTF8 (Join-Path $proc 'metadata_affiliations.csv')){ $meta[$m.rec_id] = $m }

$out = New-Object System.Collections.ArrayList
function Add-Row($field, $value, $n, $den){
  $pct = if($den -gt 0){ Format-Num ([math]::Round(100 * $n / $den, 1)) } else { '' }
  [void]$out.Add([pscustomobject][ordered]@{ field = $field; value = $value; n = $n; denominator = $den; percent = $pct })
}

# ---- who writes: author affiliation countries
# Countries come from the charting (full text or DOI landing page); when the charting
# could not determine them, the OpenAlex affiliation countries are used as a fallback.
$known = New-Object System.Collections.ArrayList
foreach($p in $part){
  if($p.author_countries -notin @('not-stated', 'no-fulltext', '')){
    $srcA = if($p.fulltext -eq 'yes'){ 'charting (full text)' } else { 'charting (landing page)' }
    [void]$known.Add([pscustomobject]@{ rec_id = $p.rec_id; author_countries = $p.author_countries; source = $srcA })
  } elseif($meta[$p.rec_id] -and $meta[$p.rec_id].openalex_countries){
    [void]$known.Add([pscustomobject]@{ rec_id = $p.rec_id; author_countries = $meta[$p.rec_id].openalex_countries; source = 'OpenAlex metadata (fallback)' })
  }
}
Add-Row 'author_countries' 'known' $known.Count $part.Count
foreach($g in ($known | Group-Object source)){ Add-Row 'author_countries source' $g.Name $g.Count $known.Count }
$regCount = @{}
$ctyCount = @{}
foreach($p in $known){
  $codes = @(Get-Set $p.author_countries)
  foreach($c in $codes){
    if(-not $region.ContainsKey($c)){ throw "Unknown country code '$c' in $($p.rec_id): extend the region table." }
    $ctyCount[$c] = 1 + [int]$ctyCount[$c]
  }
  foreach($g in @($codes | ForEach-Object { $region[$_] } | Sort-Object -Unique)){ $regCount[$g] = 1 + [int]$regCount[$g] }
}
foreach($g in $regionCodes.Keys | Sort-Object){ Add-Row 'author_region (>=1 author)' $g ([int]$regCount[$g]) $known.Count }
foreach($c in ($ctyCount.Keys | Sort-Object { -$ctyCount[$_] }, { $_ })){ Add-Row 'author_country (>=1 author)' $c $ctyCount[$c] $known.Count }
$onlyNAEU = @($known | Where-Object { $rs = @(Get-Set $_.author_countries | ForEach-Object { $region[$_] } | Sort-Object -Unique); @($rs | Where-Object { $_ -notin @('Northern America', 'Europe') }).Count -eq 0 }).Count
Add-Row 'author_region (all authors)' 'only Northern America and/or Europe' $onlyNAEU $known.Count

# ---- who is tested: identity cues (model-testing studies)
$testing = @($part | Where-Object { $type[$_.rec_id] -in @('empirical-evaluation', 'mitigation', 'mechanistic') })
foreach($v in @('race-ethnicity', 'gender', 'age', 'nationality-region', 'religion', 'language-dialect', 'political', 'socioeconomic', 'education-expertise', 'disability-health', 'sexuality', 'other', 'none', 'not-stated')){
  Add-Row 'identity_cues (model-testing studies)' $v @($testing | Where-Object { (Get-Set $_.identity_cues) -contains $v }).Count $testing.Count
}
foreach($p in @($part | Where-Object { $_.race_categories -ne '' })){ Add-Row 'race_categories' ("{0}: {1}" -f $p.rec_id, $p.race_categories) 1 1 }

# ---- whose judgement: human data and baseline
foreach($v in @('participants', 'annotators', 'experts', 'online-community', 'none')){
  Add-Row 'human_data (all studies)' $v @($part | Where-Object { (Get-Set $_.human_data) -contains $v }).Count $part.Count
}
$withHumans = @($part | Where-Object { $_.human_race_reported -in @('yes', 'no') })
Add-Row 'human_race_reported (studies with participants/annotators/experts)' 'yes' @($withHumans | Where-Object human_race_reported -eq 'yes').Count $withHumans.Count
Add-Row 'human_origin (studies with human data)' 'not-stated' @($part | Where-Object { $_.human_origin -eq 'not-stated' }).Count @($part | Where-Object { $_.human_origin -notin @('n/a', '') }).Count
foreach($v in @('ground-truth', 'counterfactual', 'human-consensus', 'expert-judgment', 'llm-judge', 'authors-rubric', 'other', 'not-stated')){
  Add-Row 'baseline_source (model-testing studies)' $v @($testing | Where-Object { (Get-Set $_.baseline_source) -contains $v }).Count $testing.Count
}
foreach($p in @($part | Where-Object { $_.baseline_population -ne '' })){ Add-Row 'baseline_population' ("{0}: {1}" -f $p.rec_id, $p.baseline_population) 1 1 }

# ---- in which language (model-testing studies, full text)
$langNS = @($testing | Where-Object { $_.languages_evaluated -in @('not-stated', '') }).Count
$langEN = @($testing | Where-Object { $l = @(Get-Set $_.languages_evaluated); $l.Count -eq 1 -and $l[0] -eq 'English' }).Count
$langNonEN = @($testing | Where-Object { @(Get-Set $_.languages_evaluated | Where-Object { $_ -notin @('English', 'not-stated', 'n/a') }).Count -gt 0 }).Count
$langPT = @($testing | Where-Object { (Get-Set $_.languages_evaluated) -contains 'Portuguese' }).Count
Add-Row 'languages_evaluated (model-testing studies)' 'not-stated' $langNS $testing.Count
Add-Row 'languages_evaluated (model-testing studies)' 'English only' $langEN $testing.Count
Add-Row 'languages_evaluated (model-testing studies)' 'includes a language other than English' $langNonEN $testing.Count
Add-Row 'languages_evaluated (model-testing studies)' 'includes Portuguese' $langPT $testing.Count

$out | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'participation_summary.csv')

# ---- validation of author countries against OpenAlex
$val = New-Object System.Collections.ArrayList
foreach($p in @($known | Where-Object source -eq 'charting (full text)')){
  $m = $meta[$p.rec_id]
  if(-not $m -or -not $m.openalex_countries){ continue }
  $a = @(Get-Set $p.author_countries); $b = @(Get-Set $m.openalex_countries)
  $inter = @($a | Where-Object { $b -contains $_ }).Count
  $union = @(($a + $b) | Sort-Object -Unique).Count
  [void]$val.Add([pscustomobject][ordered]@{ rec_id = $p.rec_id; charting = ($a -join ';'); openalex = ($b -join ';')
    exact = [int]($inter -eq $union); jaccard = (Format-Num ([math]::Round($inter / $union, 3))) })
}
$val | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'participation_validation.csv')
$exact = @($val | Where-Object exact -eq 1).Count
$jmean = if($val.Count){ ($val | ForEach-Object { [double]::Parse($_.jaccard, [Globalization.CultureInfo]::InvariantCulture) } | Measure-Object -Average).Average } else { 0 }
Write-Output ("Studies coded: {0}; with known author countries: {1}; model-testing: {2}" -f $part.Count, $known.Count, $testing.Count)
foreach($g in ($known | Group-Object source)){ Write-Output ("  author countries from {0}: {1}" -f $g.Name, $g.Count) }
Write-Output ("Validation against OpenAlex: {0} studies; exact country-set agreement {1}%; mean Jaccard {2}" -f $val.Count, (Format-Num ([math]::Round(100 * $exact / [math]::Max(1, $val.Count), 1))), (Format-Num ([math]::Round($jmean, 3))))
Write-Output "written: participation_summary.csv, participation_validation.csv"
