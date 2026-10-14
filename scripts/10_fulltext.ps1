<#
  10_fulltext.ps1 - Full-text retrieval for the participation charting (revision R1).

  For every eligible study (data/processed/eligible_studies.csv) this script
  tries to obtain an openly available PDF, in this order:
    1. arXiv            (arXiv id)                      -> https://arxiv.org/pdf/<id>
    2. Zenodo           (DOI 10.5281/zenodo.N)          -> first PDF file of the record
    3. OpenAlex         (DOI or OpenAlex W-id)          -> open-access pdf_url of any location
  and extracts its text with pdftotext (Poppler). PDFs and text are written to a
  local cache OUTSIDE the repository (they are not redistributed); only the
  provenance table is written to the repository.

  It also stores, for later validation only, the affiliation countries that
  OpenAlex and Zenodo record for each study. These are NOT shown to the coders.

  Output: data/processed/fulltext_status.csv
            rec_id, fulltext_source, fulltext_url, status, pages, text_chars
          data/processed/metadata_affiliations.csv
            rec_id, openalex_countries, openalex_institutions, zenodo_affiliations
  Requirements: PowerShell 5.1+, internet access, pdftotext/pdfinfo on PATH.

  Usage: ./scripts/10_fulltext.ps1 [-CacheDir <folder>]
#>
param([string]$CacheDir = (Join-Path $env:TEMP 'paper-cts-fulltext'))
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$mail = 'anonymous@example.org'
$hdr  = @{ 'User-Agent' = "sycophancy-review/1.1 (mailto:$mail)" }

# OpenAlex: request only the fields needed. The full record carries abstract_inverted_index, whose keys can differ
# only by letter case; Windows PowerShell 5.1 then fails to parse the JSON and silently returns a string.
$oaSel = '?select=id,doi,authorships,best_oa_location,locations'
$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'
New-Item -ItemType Directory -Force $CacheDir | Out-Null

function Get-Json($url){
  for($i = 0; $i -lt 3; $i++){
    try {
      $res = Invoke-RestMethod -Uri $url -Headers $hdr -TimeoutSec 60
      if($res -is [string]){ return $null }   # JSON that PowerShell 5.1 could not parse
      return $res
    }
    catch {
      $code = 0
      if($_.Exception.Response){ $code = [int]$_.Exception.Response.StatusCode }
      if($code -ne 0 -and $code -ne 429 -and $code -lt 500){ return $null }
      Start-Sleep -Seconds (3 * ($i + 1))
    }
  }
  return $null
}

# Downloads $url to $out and returns $true only if the file is a PDF.
function Save-Pdf($url, $out){
  try {
    Invoke-WebRequest -Uri $url -Headers $hdr -OutFile $out -TimeoutSec 120 -UseBasicParsing -MaximumRedirection 10
  } catch { return $false }
  if(-not (Test-Path $out)){ return $false }
  $fs = [IO.File]::OpenRead($out)
  try { $b = New-Object byte[] 5; [void]$fs.Read($b, 0, 5) } finally { $fs.Close() }
  if([Text.Encoding]::ASCII.GetString($b) -ne '%PDF-'){ Remove-Item $out -Force; return $false }
  return $true
}

$rows = @(Import-Csv -Encoding UTF8 (Join-Path $proc 'eligible_studies.csv'))
$status = New-Object System.Collections.ArrayList
$meta   = New-Object System.Collections.ArrayList
$n = 0
foreach($r in $rows){
  $n++
  $rec = $r.rec_id
  $pdf = Join-Path $CacheDir "$rec.pdf"
  $doi = ([string]$r.doi).ToLower() -replace '^https?://doi\.org/', ''
  $axv = ([string]$r.arxiv_id).Trim()

  # ---- metadata (validation only)
  $oa = $null
  if($doi){ $oa = Get-Json ("https://api.openalex.org/works/doi:" + $doi + $oaSel) }
  if(-not $oa -and $r.url -match 'openalex\.org/(W\d+)'){ $oa = Get-Json ("https://api.openalex.org/works/" + $Matches[1] + $oaSel) }
  if(-not $oa -and $axv){ $oa = Get-Json ("https://api.openalex.org/works/doi:10.48550/arxiv." + ($axv.ToLower() -replace 'v\d+$', '') + $oaSel) }
  $oaCountries = ''; $oaInst = ''
  if($oa){
    $auth = @($oa.authorships)
    $oaCountries = (@($auth | ForEach-Object { @($_.countries) } | Where-Object { $_ }) | Sort-Object -Unique) -join ';'
    $oaInst = (@($auth | ForEach-Object { @($_.institutions) | ForEach-Object { $_.display_name } } | Where-Object { $_ }) | Sort-Object -Unique) -join '; '
  }
  $zen = $null; $zenAff = ''
  if($doi -match '^10\.5281/zenodo\.(\d+)$'){
    $zen = Get-Json ("https://zenodo.org/api/records/" + $Matches[1])
    if($zen){ $zenAff = (@($zen.metadata.creators | ForEach-Object { $_.affiliation } | Where-Object { $_ }) | Sort-Object -Unique) -join '; ' }
  }
  [void]$meta.Add([pscustomobject][ordered]@{ rec_id = $rec; openalex_countries = $oaCountries; openalex_institutions = $oaInst; zenodo_affiliations = $zenAff })

  # ---- candidate PDF URLs, in order
  $cands = New-Object System.Collections.ArrayList
  if($axv){ [void]$cands.Add(@('arxiv', ("https://arxiv.org/pdf/" + $axv))) }
  if($zen){
    foreach($f in @($zen.files)){
      if(([string]$f.key) -match '\.pdf$'){ [void]$cands.Add(@('zenodo', [string]$f.links.self)); break }
    }
  }
  if($oa){
    $urls = @()
    if($oa.best_oa_location -and $oa.best_oa_location.pdf_url){ $urls += $oa.best_oa_location.pdf_url }
    foreach($l in @($oa.locations)){ if($l.pdf_url){ $urls += $l.pdf_url } }
    foreach($u in ($urls | Select-Object -Unique)){ [void]$cands.Add(@('openalex-oa', [string]$u)) }
  }

  $src = 'none'; $used = ''; $st = 'no-candidate'
  $side = Join-Path $CacheDir "$rec.src.txt"
  if((Test-Path $pdf) -and (Test-Path $side)){
    $parts = (Get-Content $side -TotalCount 1) -split "`t"
    $src = $parts[0]; $used = $parts[1]; $st = 'ok'
  } else {
    if(Test-Path $pdf){ Remove-Item $pdf -Force }
    foreach($c in $cands){
      $st = 'not-retrieved'
      if(Save-Pdf $c[1] $pdf){ $src = $c[0]; $used = $c[1]; $st = 'ok'; Set-Content -Path $side -Value ($src + "`t" + $used); break }
      if($c[0] -eq 'arxiv'){ Start-Sleep -Seconds 3 } else { Start-Sleep -Seconds 1 }
    }
    if($src -eq 'arxiv'){ Start-Sleep -Seconds 3 }
  }

  $pages = ''; $chars = ''
  if($st -eq 'ok'){
    $txt = Join-Path $CacheDir "$rec.txt"
    # pdftotext and pdfinfo print harmless warnings on stderr; with 'Stop' PowerShell 5.1 would treat them as errors
    $ErrorActionPreference = 'Continue'
    & pdftotext -enc UTF-8 $pdf $txt 2>&1 | Out-Null
    & pdftotext -enc UTF-8 -f 1 -l 2 $pdf (Join-Path $CacheDir "$rec.p12.txt") 2>&1 | Out-Null
    $info = @(& pdfinfo $pdf 2>&1 | ForEach-Object { [string]$_ })
    $ErrorActionPreference = 'Stop'
    $pl = @($info | Where-Object { $_ -match '^Pages:\s+(\d+)' })
    if($pl.Count -gt 0 -and $pl[0] -match '(\d+)'){ $pages = $Matches[1] }
    if(Test-Path $txt){ $chars = (Get-Item $txt).Length }
  }
  [void]$status.Add([pscustomobject][ordered]@{ rec_id = $rec; fulltext_source = $src; fulltext_url = $used; status = $st; pages = $pages; text_chars = $chars })
  if($n % 20 -eq 0){ Write-Output ("{0}/{1} processed" -f $n, $rows.Count) }
}
$status | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'fulltext_status.csv')
$meta   | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'metadata_affiliations.csv')
$ok = @($status | Where-Object status -eq 'ok').Count
Write-Output ("Full text retrieved: {0} of {1}" -f $ok, $rows.Count)
foreach($g in ($status | Group-Object fulltext_source)){ Write-Output ("  {0}: {1}" -f $g.Name, $g.Count) }
Write-Output "written: fulltext_status.csv, metadata_affiliations.csv (cache: $CacheDir)"
