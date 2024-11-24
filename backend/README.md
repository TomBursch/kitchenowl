## Contributing

Take a look at the general contribution rules [here](../CONTRIBUTING.md).

### Requirements
- Python 3.11+

### Setup & Install
- If you haven't already, switch to the backend folder `cd backend`
- Create a python environment `python3 -m venv venv`
- Activate your python environment `source venv/bin/activate` (environment can be deactivated with `deactivate`)
- Install dependencies `pip3 install -r requirements.txt`
- Initialize/Upgrade requirements for the recipe scraper `python -c "import nltk; nltk.download('averaged_perceptron_tagger_eng', download_dir='./venv/nltk_data')"`
- Initialize/Upgrade the SQLite database with `flask db upgrade`
- Run debug server with `python3 wsgi.py` or without debugging `flask run`
- The backend should be reachable at `localhost:5000`
