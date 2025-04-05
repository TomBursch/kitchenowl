## Contributing

Take a look at the general contribution rules [here](../CONTRIBUTING.md).

### Requirements
- Python 3.12+
- [UV](https://docs.astral.sh/uv/getting-started/)

### Setup & Install
- If you haven't already, switch to the backend folder `cd backend`
- Install dependencies `pip3 install -r requirements.txt`
- Optionally: Activate your python environment `source .venv/bin/activate` (allows you to omit `uv run` in the following steps, environment can be deactivated with `deactivate`)
- Initialize/Upgrade requirements for the recipe scraper `uv run python -c "import nltk; nltk.download('averaged_perceptron_tagger_eng', download_dir='./venv/nltk_data')"`
- Initialize/Upgrade the SQLite database with `uv run flask db upgrade`
- Run debug server with `uv run wsgi.py`
- The backend should be reachable at `localhost:5000`
