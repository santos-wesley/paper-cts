<#
  02_dedup.ps1 — Pool the raw records from the three databases and deduplicate.

  Deduplication key: normalized title (lowercase, alphanumeric only). This is the
  most reliable cross-source identifier here, because arXiv records have no DOI
  while the same work appears in OpenAlex/Semantic Scholar with a DOI. When two
  records share a normalized title they are merged, keeping the longest abstract
  and recording every source that returned the work.

  Output: data/processed/pooled_dedup.csv and .json
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$raw  = Join-Path $root 'data\raw'
$proc = Join-Path $root 'data\processed'
New-Item -ItemType Directory -Force $proc | Out-Null

function NormTitle($t){ ((([string]$t) -replace '[^a-zA-Z0-9 ]',' ') -replace '\s+',' ').Trim().ToLower() }

$all = @()
foreach($f in 'arxiv.json','openalex.json','semanticscholar.json'){
  $recs = Get-Content -Raw -Encoding UTF8 (Join-Path $raw $f) | ConvertFrom-Json
  $all += @($recs)
}
Write-Output ("pooled raw records: " + $all.Count)

$byTitle = [ordered]@{}
foreach($r in $all){
  $k = NormTitle $r.title
  if([string]::IsNullOrWhiteSpace($k)){ continue }
  if(-not $byTitle.Contains($k)){
    $byTitle[$k] = [pscustomobject]@{
      title=$r.title; year=$r.year; doi=$r.doi; arxiv_id=$r.arxiv_id;
      abstract=$r.abstract; url=$r.url; sources=@($r.source)
    }
  } else {
    $m = $byTitle[$k]
    if($r.source -notin $m.sources){ $m.sources += $r.source }
    if([string]::IsNullOrWhiteSpace($m.doi) -and $r.doi){ $m.doi = $r.doi }
    if([string]::IsNullOrWhiteSpace($m.arxiv_id) -and $r.arxiv_id){ $m.arxiv_id = $r.arxiv_id }
    if(([string]$r.abstract).Length -gt ([string]$m.abstract).Length){ $m.abstract = $r.abstract }
    if([string]::IsNullOrWhiteSpace($m.year) -and $r.year){ $m.year = $r.year }
  }
}
$dedup = @($byTitle.Values)
Write-Output ("unique records after dedup (by title): " + $dedup.Count)
Write-Output ("duplicates removed: " + ($all.Count - $dedup.Count))
$withAbs = @($dedup | Where-Object { -not [string]::IsNullOrWhiteSpace($_.abstract) }).Count
Write-Output ("records with an abstract: " + $withAbs)

# assign a stable record id
$i = 0
$dedup = $dedup | ForEach-Object { $i++; $_ | Add-Member -NotePropertyName rec_id -NotePropertyValue ("R{0:D4}" -f $i) -PassThru }

$dedup | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $proc 'pooled_dedup.json')
$dedup | ForEach-Object { [pscustomobject]@{ rec_id=$_.rec_id; title=$_.title; year=$_.year; doi=$_.doi; arxiv_id=$_.arxiv_id; sources=($_.sources -join '+'); url=$_.url } } |
  Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'pooled_dedup.csv')
Write-Output "written: data/processed/pooled_dedup.{json,csv}"