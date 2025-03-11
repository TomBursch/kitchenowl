import os
import psycopg2
import requests
from recipe_scrapers import scrape_html
from bs4 import BeautifulSoup
import openai
from dotenv import load_dotenv
import json
import time

load_dotenv("../.env")


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






