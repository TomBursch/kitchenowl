import os
import psycopg2
import requests
from recipe_scrapers import scrape_html
from bs4 import BeautifulSoup
import openai
from dotenv import load_dotenv
import json
import time

