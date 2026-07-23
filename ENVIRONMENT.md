# Environment

The search and screening were executed on:

| component | version |
|---|---|
| Operating system | Microsoft Windows 10 (10.0.19045) |
| Shell | Windows PowerShell 5.1.19041 |
| Git | 2.33.0.windows.2 |
| Search date | 2026-07-08 |

## APIs queried
| service | endpoint | auth |
|---|---|---|
| arXiv | `http://export.arxiv.org/api/query` | none |
| OpenAlex | `https://api.openalex.org/works` | polite pool via `mailto` |
| Semantic Scholar | `https://api.semanticscholar.org/graph/v1/paper/search/bulk` | `x-api-key` from env var `S2_API_KEY` (optional) |

## Notes on API quirks handled by the scripts
- **OpenAlex** returns `count = 0` when `abstract_inverted_index` is requested
  together with `per-page > 1`, and when `cursor` pagination is used for this
  query. The script therefore paginates with `?page=N`, `per-page=100`, and does
  **not** request `abstract_inverted_index`; abstracts for OpenAlex records are
  recovered by cross-match with arXiv/Semantic Scholar during deduplication.
- **Semantic Scholar** enforces ~1 request/second; the script sleeps 1.3 s
  between bulk pages and retries on HTTP 429 with backoff.
- All HTTP GETs use a retry-with-backoff wrapper (`Get-Json`).

The scripts require only PowerShell and internet access; no external modules.
