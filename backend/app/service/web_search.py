"""Web search for the recipe agent.

Uses the Brave Search API when ``BRAVE_SEARCH_API_KEY`` is configured
(recommended — DuckDuckGo's HTML endpoint regularly serves anti-bot
challenges and returns no usable results from server IPs). Falls back to
scraping the DuckDuckGo HTML endpoint when no API key is available.
"""

from __future__ import annotations

import logging
import os
from typing import Any
from urllib.parse import parse_qs, unquote, urlparse

import requests
from bs4 import BeautifulSoup


_logger = logging.getLogger(__name__)

_BRAVE_ENDPOINT = "https://api.search.brave.com/res/v1/web/search"
_DDG_ENDPOINT = "https://duckduckgo.com/html/"
_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}
_TIMEOUT = 8


def _clean_url(href: str) -> str | None:
    """DuckDuckGo wraps result links in /l/?uddg=<encoded>. Unwrap them."""
    if not href:
        return None
    parsed = urlparse(href)
    if parsed.path == "/l/" and parsed.query:
        qs = parse_qs(parsed.query)
        target = qs.get("uddg", [None])[0]
        if target:
            return unquote(target)
    if parsed.scheme in ("http", "https"):
        return href
    return None


def _search_brave(
    query: str,
    max_results: int,
    brave_api_key: str | None = None,
) -> list[dict[str, Any]]:
    api_key = (brave_api_key or "").strip() or os.getenv("BRAVE_SEARCH_API_KEY")
    if not api_key:
        return []
    try:
        res = requests.get(
            _BRAVE_ENDPOINT,
            params={"q": query, "count": max(1, min(20, max_results))},
            headers={
                "Accept": "application/json",
                "X-Subscription-Token": api_key,
            },
            timeout=_TIMEOUT,
        )
    except requests.RequestException:
        _logger.warning("Brave search request failed", exc_info=True)
        return []

    if res.status_code != 200:
        _logger.info(
            "Brave search returned HTTP %s: %s",
            res.status_code,
            res.text[:200],
        )
        return []

    try:
        data = res.json()
    except ValueError:
        return []

    items = ((data.get("web") or {}).get("results")) or []
    out: list[dict[str, Any]] = []
    for item in items[:max_results]:
        url = item.get("url")
        if not url:
            continue
        out.append(
            {
                "title": (item.get("title") or "").strip(),
                "url": url,
                "snippet": (item.get("description") or "").strip(),
            }
        )
    return out


def _search_duckduckgo(query: str, max_results: int) -> list[dict[str, Any]]:
    try:
        res = requests.post(
            _DDG_ENDPOINT,
            data={"q": query, "kl": "wt-wt"},
            headers=_HEADERS,
            timeout=_TIMEOUT,
        )
    except requests.RequestException:
        _logger.warning("DuckDuckGo search request failed", exc_info=True)
        return []

    if res.status_code != 200:
        return []

    soup = BeautifulSoup(res.text, "html.parser")
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    for result in soup.select("div.result"):
        title_el = result.select_one("a.result__a")
        snippet_el = result.select_one("a.result__snippet, div.result__snippet")
        if not title_el:
            continue
        href = _clean_url(title_el.get("href", ""))
        if not href or href in seen:
            continue
        seen.add(href)
        out.append(
            {
                "title": title_el.get_text(strip=True),
                "url": href,
                "snippet": snippet_el.get_text(" ", strip=True) if snippet_el else "",
            }
        )
        if len(out) >= max_results:
            break
    return out


def search_recipes_web(
    query: str,
    max_results: int = 5,
    brave_api_key: str | None = None,
) -> list[dict[str, Any]]:
    """Return up to ``max_results`` web hits for ``query``.

    Each hit is a dict with ``title``, ``url`` and ``snippet``. The list is
    empty if every backend fails. Order of preference:

    1. Brave Search API (when ``BRAVE_SEARCH_API_KEY`` is set) — reliable
       JSON results, no anti-bot challenges.
    2. DuckDuckGo HTML scraping — no key required but routinely blocked
       from datacenter IPs.
    """
    query = (query or "").strip()
    if not query:
        return []

    enriched = f"{query} recipe"

    results = _search_brave(enriched, max_results, brave_api_key=brave_api_key)
    if results:
        return results

    return _search_duckduckgo(enriched, max_results)
