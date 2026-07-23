<#
  01_search.ps1 — Reproducible systematic search for the review
  "Sociological and Philosophical Aspects of Sycophancy in Language Models".

  Queries three open bibliographic databases (arXiv, OpenAlex, Semantic Scholar)
  plus a Lusophone probe, records the exact query strings and raw counts, and
  saves all retrieved records (with abstracts) to data/raw/.

  Requirements: PowerShell 5.1+, internet access.
  Semantic Scholar API key (optional) is read from the environment variable
  S2_API_KEY — it is NEVER stored in this repository.

  Usage:  $env:S2_API_KEY = '<your key>'; ./scripts/01_search.ps1
#>
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$mail = 'anonymous@example.org'
$hdr  = @{ 'User-Agent' = "sycophancy-review/1.0 (mailto:$mail)" }

$root = Split-Path -Parent $PSScriptRoot
$raw  = Join-Path $root 'data\raw'
New-Item -ItemType Directory -Force $raw | Out-Null
$searchDate = (Get-Date -Format 'yyyy-MM-dd')
$log = [ordered]@{ search_date = $searchDate; databases = @() }

function Get-AbstractFromIndex($inv){
  if(-not $inv){ return '' }
  $pos = @{}
  foreach($p in $inv.PSObject.Properties){ foreach($i in $p.Value){ $pos[[int]$i] = $p.Name } }
  return (($pos.GetEnumerator() | Sort-Object Name | ForEach-Object { $_.Value }) -join ' ')
}
# Robust GET with retries (handles transient errors, 429, and empty responses)
function Get-Json($url, $headers, [switch]$retryOnZero){
  for($a=1; $a -le 6; $a++){
    try {
      $r = Invoke-RestMethod -Headers $headers $url
      if($retryOnZero -and $r.meta -and $r.meta.count -eq 0 -and $a -lt 6){ Start-Sleep -Seconds 2; continue }
      return $r
    } catch {
      if($a -eq 6){ throw }
      Start-Sleep -Seconds ([math]::Min(30, 3*$a))
    }
  }
}

# ------------------------------------------------------------------ arXiv
$axQuery = 'abs:sycophancy AND (abs:"language model" OR abs:"large language model" OR abs:LLM OR abs:chatbot OR abs:RLHF)'
$ax = @(); $axTotal = $null
foreach($start in 0,100,200,300){
  $u = "http://export.arxiv.org/api/query?search_query=" + [uri]::EscapeDataString($axQuery) + "&start=$start&max_results=100"
  $x = $null
  for($a=1;$a -le 5;$a++){ try{ $x=[xml](Invoke-WebRequest -UseBasicParsing -Headers $hdr $u).Content; break }catch{ Start-Sleep -Seconds (2*$a) } }
  if($null -eq $axTotal){
    $ns = New-Object System.Xml.XmlNamespaceManager($x.NameTable); $ns.AddNamespace('os','http://a9.com/-/spec/opensearch/1.1/')
    $axTotal = [int]$x.SelectSingleNode('//os:totalResults',$ns).InnerText
  }
  $entries = @($x.feed.entry)
  if($entries.Count -eq 0){ break }
  foreach($e in $entries){
    if($null -eq $e){ continue }
    $aid = ($e.id -replace 'http://arxiv.org/abs/','') -replace 'v\d+$',''
    $ax += [pscustomobject]@{ source='arXiv'; ext_id=$aid; doi=''; arxiv_id=$aid;
      title=([string]$e.title -replace '\s+',' ').Trim(); year=([string]$e.published).Substring(0,4);
      abstract=([string]$e.summary -replace '\s+',' ').Trim(); url=("https://arxiv.org/abs/"+$aid) }
  }
  Start-Sleep -Milliseconds 900
}
$ax = $ax | Sort-Object ext_id -Unique
Write-Output ("arXiv total=$axTotal retrieved=" + $ax.Count)
$log.databases += [ordered]@{ name='arXiv'; endpoint='http://export.arxiv.org/api/query'; query=$axQuery; total=$axTotal; retrieved=$ax.Count }

# ------------------------------------------------------------------ OpenAlex
# NOTE: cursor pagination intermittently returns count=0 for this query on the
# OpenAlex API; page-based pagination is reliable, so we use ?page=N (<=10000 results).
$oaFilter = 'title.search:sycophancy,from_publication_date:2022-01-01'
$oa = @(); $oaTotal = $null; $page = 1
while($true){
  # (abstract_inverted_index is omitted: OpenAlex returns count=0 when it is
  #  selected together with per-page>1; abstracts are recovered by cross-match.)
  $u = "https://api.openalex.org/works?filter=$oaFilter&per-page=100&page=$page&select=id,doi,title,publication_year&mailto=$mail"
  $r = Get-Json $u $hdr -retryOnZero
  if($null -eq $oaTotal){ $oaTotal = $r.meta.count }
  if(-not $r.results -or $r.results.Count -eq 0){ break }
  foreach($w in $r.results){
    $oa += [pscustomobject]@{ source='OpenAlex'; ext_id=($w.id -replace 'https://openalex.org/','');
      doi=([string]$w.doi -replace 'https://doi.org/',''); arxiv_id='';
      title=([string]$w.title -replace '\s+',' ').Trim(); year=[string]$w.publication_year;
      abstract=(Get-AbstractFromIndex $w.abstract_inverted_index); url=$w.id }
  }
  if($oa.Count -ge $oaTotal){ break }
  $page++
  Start-Sleep -Milliseconds 500
}
Write-Output ("OpenAlex total=$oaTotal retrieved=" + $oa.Count)
$log.databases += [ordered]@{ name='OpenAlex'; endpoint='https://api.openalex.org/works'; query=$oaFilter; total=$oaTotal; retrieved=$oa.Count }

# ------------------------------------------------------------------ Semantic Scholar (bulk, keyword matches)
$s2 = @(); $s2Total = $null
$s2Query = 'sycophancy + ("language model" | LLM | chatbot | RLHF)'
$s2hdr = @{ 'User-Agent' = $hdr['User-Agent'] }
if($env:S2_API_KEY){ $s2hdr['x-api-key'] = $env:S2_API_KEY }
$token = $null
try {
  do {
    $u = "https://api.semanticscholar.org/graph/v1/paper/search/bulk?query=" + [uri]::EscapeDataString($s2Query) + "&fields=title,abstract,year,externalIds"
    if($token){ $u += "&token=$token" }
    $r = Get-Json $u $s2hdr
    if($null -eq $s2Total){ $s2Total = $r.total }
    foreach($p in $r.data){
      $doi=''; $aid=''
      if($p.externalIds){ $doi=[string]$p.externalIds.DOI; $aid=[string]$p.externalIds.ArXiv }
      $s2 += [pscustomobject]@{ source='SemanticScholar'; ext_id=$p.paperId; doi=$doi; arxiv_id=$aid;
        title=([string]$p.title -replace '\s+',' ').Trim(); year=[string]$p.year;
        abstract=([string]$p.abstract -replace '\s+',' ').Trim(); url=("https://www.semanticscholar.org/paper/"+$p.paperId) }
    }
    $token = $r.token
    Start-Sleep -Milliseconds 1300   # respect 1 request/second
  } while($token)
} catch { Write-Output ("Semantic Scholar: stopped (" + $_.Exception.Message + ")") }
Write-Output ("SemanticScholar total=$s2Total retrieved=" + $s2.Count)
$log.databases += [ordered]@{ name='Semantic Scholar'; endpoint='https://api.semanticscholar.org/graph/v1/paper/search/bulk'; query=$s2Query; total=$s2Total; retrieved=$s2.Count }

# ------------------------------------------------------------------ Lusophone probe (OpenAlex)
$lus = [ordered]@{}
foreach($term in 'sicof%C3%A2ncia','bajula%C3%A7%C3%A3o','adula%C3%A7%C3%A3o'){
  $r = Get-Json ("https://api.openalex.org/works?filter=title_and_abstract.search:$term&per-page=1&mailto=$mail") $hdr
  $lus[[uri]::UnescapeDataString($term)] = $r.meta.count
  Start-Sleep -Milliseconds 400
}
Write-Output ("Lusophone probe (OpenAlex): " + (($lus.GetEnumerator()|ForEach-Object{ $_.Key+'='+$_.Value }) -join '; '))
$log.databases += [ordered]@{ name='OpenAlex (Lusophone probe)'; endpoint='https://api.openalex.org/works'; query='title_and_abstract.search: {sicofancia, bajulacao, adulacao}'; total=(($lus.Values) -join '/'); retrieved=0 }

# ------------------------------------------------------------------ save
$ax | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $raw 'arxiv.json')
$oa | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $raw 'openalex.json')
$s2 | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $raw 'semanticscholar.json')
$log | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $root 'data\search_log.json')
Write-Output ("SEARCH DATE: " + $searchDate + "  | raw files written to data/raw/")
