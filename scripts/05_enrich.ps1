<#
  05_enrich.ps1 - Metadata enrichment of the included studies (revision R1).

  For every included study (data/processed/included_studies.csv) this script
  retrieves document-type metadata and, when the pooled record has no abstract,
  recovers it from open APIs. Nothing is inferred: each field records where it
  came from.

    - Zenodo  (DOI 10.5281/zenodo.N): resource_type, description (abstract)
    - OpenAlex (W-id from the record URL, or DOI): type, source, language,
                abstract_inverted_index (abstract)
    - Semantic Scholar (S2 paper id or DOI), only if the abstract is still
                missing: abstract, publicationTypes, venue
    - Crossref (DOI, non-Zenodo), only if the abstract is still missing:
                type, abstract
    - arXiv (arXiv id), only if the abstract is still missing: summary
    - Semantic Scholar again, in a slow second pass (5 s between requests),
                for records indexed only there that still have no abstract

  Output: data/processed/enriched_included.json and enriched_included.csv
  Requirements: PowerShell 5.1+, internet access. The Semantic Scholar key is
  optional and read from the environment variable S2_API_KEY (never stored).

  Usage: ./scripts/05_enrich.ps1
#>
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$mail  = 'anonymous@example.org'
$hdr   = @{ 'User-Agent' = "sycophancy-review/1.1 (mailto:$mail)" }
$s2hdr = @{ 'User-Agent' = $hdr['User-Agent'] }
if($env:S2_API_KEY){ $s2hdr['x-api-key'] = $env:S2_API_KEY }

$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'

# GET that retries only transient failures (HTTP 429, 5xx, network errors).
# Any other HTTP error (404 not found, 410 gone, 403, ...) returns $null at once.
# The last HTTP status is kept in $script:lastStatus for provenance.
$script:lastStatus = ''
function Get-Json($url, $headers){
  for($a=1; $a -le 3; $a++){
    try {
      $r = Invoke-RestMethod -Headers $headers -TimeoutSec 30 -MaximumRedirection 3 $url
      $script:lastStatus = '200'
      return $r
    } catch {
      $code = $null
      try { $code = [int]$_.Exception.Response.StatusCode } catch {}
      $script:lastStatus = if($code){ [string]$code } else { 'network-error' }
      if($code -and $code -ne 429 -and $code -lt 500){ return $null }
      if($a -eq 3){ Write-Warning "failed ($($script:lastStatus)): $url"; return $null }
      Start-Sleep -Seconds (2*$a)
    }
  }
}
# Semantic Scholar throttles anonymous clients (HTTP 429): at most three
# attempts, 6 s apart; any other error returns $null at once.
function Get-JsonS2($url, $headers){
  for($a=1; $a -le 3; $a++){
    try {
      $r = Invoke-RestMethod -Headers $headers -TimeoutSec 30 $url
      $script:lastStatus = '200'
      return $r
    } catch {
      $code = $null
      try { $code = [int]$_.Exception.Response.StatusCode } catch {}
      $script:lastStatus = if($code){ [string]$code } else { 'network-error' }
      if($code -ne 429){ return $null }
      Start-Sleep -Seconds 6
    }
  }
  Write-Warning "failed (429): $url"
  return $null
}
function Get-AbstractFromIndex($inv){
  if(-not $inv){ return '' }
  $pos = @{}
  foreach($p in $inv.PSObject.Properties){ foreach($i in $p.Value){ $pos[[int]$i] = $p.Name } }
  return (($pos.GetEnumerator() | Sort-Object Name | ForEach-Object { $_.Value }) -join ' ')
}
function Remove-Markup([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return '' }
  $t = [regex]::Replace($s, '<[^>]+>', ' ')
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  return ([regex]::Replace($t, '\s+', ' ')).Trim()
}

$pool = Get-Content -Raw -Encoding UTF8 (Join-Path $proc 'pooled_dedup.json') | ConvertFrom-Json
$byId = @{}; foreach($r in $pool){ $byId[$r.rec_id] = $r }
$inc  = @(Import-Csv -Encoding UTF8 (Join-Path $proc 'included_studies.csv'))

$rows = New-Object System.Collections.ArrayList
$n = 0
foreach($s in $inc){
  $n++
  $p    = $byId[$s.rec_id]
  $doi  = ([string]$s.doi).Trim()
  $doiL = $doi.ToLower()
  $url  = [string]$s.url
  $abs  = [string]$p.abstract
  $absSrc = ''
  if(-not [string]::IsNullOrWhiteSpace($abs)){ $absSrc = 'pooled' }
  $oaType=''; $oaSource=''; $oaSourceType=''; $oaLang=''
  $zType=''; $zSub=''; $zStatus=''; $s2Types=''; $s2Venue=''; $crType=''

  # --- Zenodo
  if($doiL -match '^10\.5281/zenodo\.(\d+)$'){
    $z = Get-Json ("https://zenodo.org/api/records/" + $Matches[1]) $hdr
    $zStatus = if($z -and $z.metadata){ 'available' } else { "unavailable (HTTP $($script:lastStatus))" }
    if($z -and $z.metadata){
      $zType = [string]$z.metadata.resource_type.type
      $zSub  = [string]$z.metadata.resource_type.subtype
      if(-not $absSrc){
        $d = Remove-Markup ([string]$z.metadata.description)
        if($d){ $abs = $d; $absSrc = 'zenodo' }
      }
    }
    Start-Sleep -Milliseconds 1100
  }

  # --- OpenAlex
  $oaUrl = $null
  if($url -match 'openalex\.org/(W\d+)'){ $oaUrl = "https://api.openalex.org/works/$($Matches[1])?mailto=$mail" }
  elseif($doi){ $oaUrl = "https://api.openalex.org/works/doi:" + $doi + "?mailto=$mail" }
  if($oaUrl){
    $o = Get-Json $oaUrl $hdr
    if($o){
      $oaType = [string]$o.type
      $oaLang = [string]$o.language
      if($o.primary_location -and $o.primary_location.source){
        $oaSource     = [string]$o.primary_location.source.display_name
        $oaSourceType = [string]$o.primary_location.source.type
      }
      if(-not $absSrc){
        $d = Get-AbstractFromIndex $o.abstract_inverted_index
        if($d){ $abs = $d; $absSrc = 'openalex' }
      }
    }
    Start-Sleep -Milliseconds 250
  }

  # --- Semantic Scholar (only if the abstract is still missing)
  if(-not $absSrc){
    $s2Url = $null
    if($url -match 'semanticscholar\.org/paper/([0-9a-f]{40})'){
      $s2Url = "https://api.semanticscholar.org/graph/v1/paper/$($Matches[1])?fields=abstract,publicationTypes,venue"
    } elseif($doi){
      $s2Url = "https://api.semanticscholar.org/graph/v1/paper/DOI:" + $doi + "?fields=abstract,publicationTypes,venue"
    }
    if($s2Url){
      $q = Get-JsonS2 $s2Url $s2hdr
      if($q){
        $s2Types = (@($q.publicationTypes) -join ';')
        $s2Venue = [string]$q.venue
        if($q.abstract){ $abs = [string]$q.abstract; $absSrc = 'semanticscholar' }
      }
      Start-Sleep -Milliseconds 1300
    }
  }

  # --- Crossref (only if the abstract is still missing; not for Zenodo DOIs)
  if(-not $absSrc -and $doi -and $doiL -notmatch '^10\.5281/'){
    $c = Get-Json ("https://api.crossref.org/works/" + $doi + "?mailto=$mail") $hdr
    if($c -and $c.message){
      $crType = [string]$c.message.type
      $d = Remove-Markup ([string]$c.message.abstract)
      if($d){ $abs = $d; $absSrc = 'crossref' }
    }
    Start-Sleep -Milliseconds 300
  }

  # --- arXiv (only if the abstract is still missing and an arXiv id exists)
  $axId = [string]$s.arxiv_id
  if(-not $axId -and $doiL -match '^10\.48550/arxiv\.(.+)$'){ $axId = $Matches[1] }
  if(-not $absSrc -and $axId){
    $x = $null
    for($a=1; $a -le 3; $a++){
      try { $x = [xml](Invoke-WebRequest -UseBasicParsing -Headers $hdr -TimeoutSec 30 ("http://export.arxiv.org/api/query?id_list=" + $axId)).Content; break }
      catch { Start-Sleep -Seconds (3*$a) }
    }
    if($x -and $x.feed.entry -and $x.feed.entry.summary){
      $d = Remove-Markup ([string]$x.feed.entry.summary)
      if($d){ $abs = $d; $absSrc = 'arxiv' }
    }
    Start-Sleep -Milliseconds 3000
  }

  if(-not $absSrc){ $abs = '' }
  [void]$rows.Add([pscustomobject][ordered]@{
    rec_id = $s.rec_id; year = $s.year; title = $s.title; doi = $doi; arxiv_id = $s.arxiv_id
    url = $url; sources = $s.sources
    openalex_type = $oaType; openalex_source = $oaSource; openalex_source_type = $oaSourceType
    openalex_language = $oaLang; zenodo_status = $zStatus; zenodo_type = $zType; zenodo_subtype = $zSub
    s2_publication_types = $s2Types; s2_venue = $s2Venue; crossref_type = $crType
    abstract_source = $absSrc; abstract = $abs
  })
  if($n % 25 -eq 0){ Write-Output ("  {0} / {1}" -f $n, $inc.Count) }
}

# --- Second pass: Semantic Scholar, slowly, for records indexed only there
# (record URL is a Semantic Scholar paper page) that still have no abstract;
# records with a DOI were already tried in the main pass. Even keyed clients
# can be throttled, so wait 5 s between requests and retry HTTP 429 up to four
# times with backoff.
$pending = @($rows | Where-Object { $_.abstract_source -eq '' -and $_.url -match 'semanticscholar\.org/paper/' })
Write-Output ("Second pass (Semantic Scholar) for {0} S2-only records without abstract" -f $pending.Count)
foreach($r in $pending){
  $s2Url = $null
  if($r.url -match 'semanticscholar\.org/paper/([0-9a-f]{40})'){
    $s2Url = "https://api.semanticscholar.org/graph/v1/paper/$($Matches[1])?fields=abstract,publicationTypes,venue"
  }
  if(-not $s2Url){ continue }
  $q = $null
  for($a=1; $a -le 4; $a++){
    Start-Sleep -Seconds 5
    try { $q = Invoke-RestMethod -Headers $s2hdr -TimeoutSec 30 $s2Url; break }
    catch {
      $code = $null
      try { $code = [int]$_.Exception.Response.StatusCode } catch {}
      if($code -ne 429){ break }
      Start-Sleep -Seconds (10*$a)
    }
  }
  if($q){
    if(-not $r.s2_publication_types){ $r.s2_publication_types = (@($q.publicationTypes) -join ';') }
    if(-not $r.s2_venue){ $r.s2_venue = [string]$q.venue }
    if($q.abstract){ $r.abstract = [string]$q.abstract; $r.abstract_source = 'semanticscholar' }
  }
}

$rows | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $proc 'enriched_included.json')
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'enriched_included.csv')

$withAbs = @($rows | Where-Object { $_.abstract_source -ne '' }).Count
Write-Output ("Included studies enriched: {0}" -f $rows.Count)
Write-Output ("  with abstract: {0}  (pooled={1}; zenodo={2}; openalex={3}; semanticscholar={4}; crossref={5}; arxiv={6})" -f $withAbs,
  @($rows | Where-Object abstract_source -eq 'pooled').Count, @($rows | Where-Object abstract_source -eq 'zenodo').Count,
  @($rows | Where-Object abstract_source -eq 'openalex').Count, @($rows | Where-Object abstract_source -eq 'semanticscholar').Count,
  @($rows | Where-Object abstract_source -eq 'crossref').Count, @($rows | Where-Object abstract_source -eq 'arxiv').Count)
Write-Output ("  without abstract: {0}" -f ($rows.Count - $withAbs))
Write-Output "written: enriched_included.json, enriched_included.csv"
