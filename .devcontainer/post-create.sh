#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="${REPO_ROOT}/backend"
FLUTTER_DIR="${REPO_ROOT}/kitchenowl"

echo "==> Setting up Python backend (uv sync)..."
cd "${BACKEND_DIR}"
uv sync
echo "==> Downloading NLTK data..."
uv run python -c "import nltk; nltk.download('averaged_perceptron_tagger_eng', download_dir='.venv/nltk_data')"
echo "==> Installing pre-commit hooks..."
uv run pre-commit install || true
echo "==> Initializing dev database..."
mkdir -p "${BACKEND_DIR}/.data"
uv run flask db upgrade || true

echo "==> Fetching Flutter packages..."
cd "${FLUTTER_DIR}"
flutter pub get || true

echo "==> Done. Backend: 'cd backend && uv run wsgi.py' | Flutter web: 'cd kitchenowl && flutter run -d web-server --web-port 8080'"
