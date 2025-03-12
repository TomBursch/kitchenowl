import os
import psycopg2
import requests
from recipe_scrapers import scrape_html
from bs4 import BeautifulSoup
import openai
from dotenv import load_dotenv
import json
import time

load_dotenv('../.env')


openai.api_key = os.getenv("OPENAI_API_KEY")

DB_CONFIG = {
    'host': os.getenv('DB_HOST'),
    'dbname': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv("DB_PASSWORD")
}

def get_db_connection():
    """Establish a connection to the PostgreSQL database."""
    conn = psycopg2.connect(
        host=DB_CONFIG['host'],
        dbname=DB_CONFIG['dbname'],
        user=DB_CONFIG['user'],
        password=DB_CONFIG['password']
    )
    return conn



def get_recipe_urls():
    with open('recipe_urls.json', 'r') as file:
        urls = json.load(file)
    return urls

def get_recipe_data(url):
    """Scrape recipe data from a given URL."""
    try:
        scraper = scrape_html(url)
        recipe = {
            'title': scraper.title(),
            'ingredients': scraper.ingredients(),
            'instructions': scraper.instructions(),
            'image_url': scraper.image(),
            'source_url': url
        }
        return recipe
    except Exception as e:
        print(f"Error scraping {url}: {e}")
        return None

