<#
  06_eligibility.ps1 - Document-type and abstract eligibility (revision R1).

  Applied to the included set after 05_enrich.ps1. Adds two criteria:

    E4 not-research-output : the record is not a research output (dataset,
        slides, audio/video, software, editorial matter, podcast episode,
        newsletter, marketing or product page, ...). Two parts:
          E4a  deterministic, from repository metadata types
               (Zenodo resource_type, OpenAlex type, Crossref type);
          E4b  title/abstract review, recorded one row per excluded record,
               with its reason, in data/processed/doctype_review.csv.
    E5 no-abstract : no abstract could be retrieved from any open source,
        so the record cannot be charted.
    DUP duplicate version : another version of the same work is already in the
        set (the title-based deduplication of 02_dedup.ps1 does not catch
        versions whose titles differ). The most complete version is kept:
        peer-reviewed over preprint, and a version with abstract over one
        without. Recorded in doctype_review.csv with code DUP.

  E4a is not applied to records with an arXiv id: arXiv only hosts research
  papers, and some arXiv records carry the DOI of an accompanying dataset.

  It also derives source_kind (where the record is published) from the DOI,
  arXiv id and OpenAlex source type; no judgement is involved.

  Output: data/processed/eligibility_decisions.csv
          data/processed/eligible_studies.csv
          data/processed/prisma_counts_r1.json
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$proc = Join-Path $root 'data\processed'
# Windows PowerShell 5.1 emits a JSON array as a single object; assign first,
# then enumerate, so that $rows holds one element per record.
$json = Get-Content -Raw -Encoding UTF8 (Join-Path $proc 'enriched_included.json') | ConvertFrom-Json
$rows = @($json)

$review = @{}
$rp = Join-Path $proc 'doctype_review.csv'
if(Test-Path $rp){
  foreach($r in Import-Csv -Encoding UTF8 $rp){ if($r.decision -eq 'exclude'){ $review[$r.rec_id] = $r } }
}

$zenodoNonResearch   = @('dataset','presentation','poster','image','video','software','lesson','audio')
$openalexNonResearch = @('dataset','paratext','peer-review','erratum','retraction','editorial','supplementary-materials','libguides','grant')
$crossrefNonResearch = @('dataset','peer-review','component','grant')

# source_kind: where the version in the set is published. A journal, conference
# or book version takes precedence over an arXiv copy. Evidence: OpenAlex source
# type, Crossref work type, or a publisher DOI prefix; records typed as
# preprints (OpenAlex 'preprint', Crossref 'posted-content') are never counted
# as journal-or-proceedings. This says where a work appeared, not whether it is
# peer-reviewed research (viewpoints and editorials appear in journals too).
$publisherPrefixes = @('10.1609/','10.1145/','10.1109/','10.1007/','10.1016/','10.1038/','10.18653/',
  '10.1142/','10.1177/','10.1093/','10.1080/','10.2196/','10.3390/','10.1140/','10.1097/','10.1001/',
  '10.1371/','10.1002/','10.1111/','10.1162/','10.4103/','10.2106/','10.14309/','10.1056/')
function Get-SourceKind($r){
  $d = ([string]$r.doi).ToLower()
  $preprintType = ([string]$r.openalex_type -eq 'preprint') -or ([string]$r.crossref_type -eq 'posted-content')
  $repoDoi = $d.StartsWith('10.48550/') -or $d.StartsWith('10.5281/') -or $d.StartsWith('10.2139/')
  $venue = ([string]$r.openalex_source_type -in @('journal','conference')) -or
           ([string]$r.crossref_type -in @('journal-article','proceedings-article','book-chapter')) -or
           (@($publisherPrefixes | Where-Object { $d.StartsWith($_) }).Count -gt 0)
  if($venue -and -not $preprintType -and -not $repoDoi){ return 'journal-or-proceedings' }
  if($r.arxiv_id -or $d.StartsWith('10.48550/arxiv')){ return 'arXiv' }
  if($d.StartsWith('10.5281/zenodo')){ return 'Zenodo' }
  if($d.StartsWith('10.2139/')){ return 'SSRN' }
  if($d.StartsWith('10.31219/') -or $d.StartsWith('10.31234/') -or $d.StartsWith('10.31235/')){ return 'OSF' }
  if($d){ return 'other-repository' }
  return 'no-identifier'
}

$decisions = New-Object System.Collections.ArrayList
$eligible  = New-Object System.Collections.ArrayList
foreach($r in $rows){
  $dec = 'include'; $reason = ''
  $isArxiv = [bool]$r.arxiv_id
  if($review.ContainsKey($r.rec_id) -and $review[$r.rec_id].code -eq 'DUP'){ $dec='exclude'; $reason = "DUP $($review[$r.rec_id].reason)" }
  elseif(-not $isArxiv -and $zenodoNonResearch -contains [string]$r.zenodo_type){ $dec='exclude'; $reason = "E4a zenodo:$($r.zenodo_type)" }
  elseif(-not $isArxiv -and $openalexNonResearch -contains [string]$r.openalex_type){ $dec='exclude'; $reason = "E4a openalex:$($r.openalex_type)" }
  elseif(-not $isArxiv -and $crossrefNonResearch -contains [string]$r.crossref_type){ $dec='exclude'; $reason = "E4a crossref:$($r.crossref_type)" }
  elseif($review.ContainsKey($r.rec_id)){ $dec='exclude'; $reason = "E4b $($review[$r.rec_id].reason)" }
  elseif([string]::IsNullOrWhiteSpace([string]$r.abstract)){ $dec='exclude'; $reason = 'E5 no-abstract' }
  $kind = Get-SourceKind $r
  [void]$decisions.Add([pscustomobject][ordered]@{
    rec_id = $r.rec_id; year = $r.year; source_kind = $kind; decision = $dec; reason = $reason; title = $r.title })
  if($dec -eq 'include'){
    [void]$eligible.Add([pscustomobject][ordered]@{
      rec_id = $r.rec_id; year = $r.year; source_kind = $kind; title = $r.title; doi = $r.doi
      arxiv_id = $r.arxiv_id; url = $r.url; abstract_source = $r.abstract_source; abstract = $r.abstract })
  }
}
$decisions | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'eligibility_decisions.csv')
$eligible  | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $proc 'eligible_studies.csv')

$dup = @($decisions | Where-Object { $_.reason -like 'DUP*' }).Count
$e4a = @($decisions | Where-Object { $_.reason -like 'E4a*' }).Count
$e4b = @($decisions | Where-Object { $_.reason -like 'E4b*' }).Count
$e5  = @($decisions | Where-Object { $_.reason -like 'E5*' }).Count
$prev = Get-Content -Raw -Encoding UTF8 (Join-Path $proc 'prisma_counts.json') | ConvertFrom-Json
[ordered]@{
  identification = $prev.identification
  duplicates_removed = $prev.duplicates_removed
  records_screened = $prev.records_screened
  excluded_screening = $prev.excluded_screening
  assessed_eligibility = $prev.assessed_eligibility
  excluded_eligibility = [ordered]@{
    E3_not_central = $prev.excluded_eligibility.E3_not_central
    duplicate_versions = $dup
    E4_not_research_output = [ordered]@{ total = ($e4a + $e4b); E4a_metadata = $e4a; E4b_review = $e4b }
    E5_no_abstract = $e5
    total = ($prev.excluded_eligibility.E3_not_central + $dup + $e4a + $e4b + $e5)
  }
  included = $eligible.Count
} | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $proc 'prisma_counts_r1.json')

Write-Output ("Included before R1 criteria: {0}" -f $rows.Count)
Write-Output ("  DUP duplicate versions:             {0}" -f $dup)
Write-Output ("  E4a not research output (metadata): {0}" -f $e4a)
Write-Output ("  E4b not research output (review):   {0}" -f $e4b)
Write-Output ("  E5  no abstract retrievable:        {0}" -f $e5)
Write-Output ("ELIGIBLE FOR CHARTING: {0}" -f $eligible.Count)
Write-Output "written: eligibility_decisions.csv, eligible_studies.csv, prisma_counts_r1.json"
