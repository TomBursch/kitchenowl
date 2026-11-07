from types import SimpleNamespace

from recipe_scrapers._exceptions import ElementNotFoundInHtml

from app.service import recipe_public_scraping


class _Scraper:
    def title(self):
        return "Plum cake"

    def total_time(self):
        return 60

    def cook_time(self):
        return 40

    def prep_time(self):
        return 20

    def yields(self):
        raise ElementNotFoundInHtml("yields")

    def description(self):
        return "A cake"

    def instructions(self):
        return "Bake it"

    def image(self):
        return "https://example.com/cake.jpg"

    def language(self):
        return "en"

    def ingredients(self):
        return []


def test_scrape_keeps_recipe_when_optional_field_is_missing(monkeypatch):
    monkeypatch.setattr(recipe_public_scraping, "scrape_html", lambda *a, **k: _Scraper())

    result = recipe_public_scraping.scrapeHTML(
        "https://example.com/cake", "<html></html>", SimpleNamespace(language="en", id=1)
    )

    assert result["recipe"]["name"] == "Plum cake"
    assert result["recipe"]["description"] == "A cake\n\nBake it"
