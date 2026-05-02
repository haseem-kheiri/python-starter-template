#!/usr/bin/env bash
set -euo pipefail

echo "Running Ruff lint..."
ruff check .

echo "Running Ruff format check..."
ruff format --check .

echo "Running mypy..."
mypy .

echo "Running pytest with coverage threshold..."
pytest --cov=. --cov-fail-under=85

echo "Running dependency vulnerability scan..."
pip-audit

echo "Running Bandit security scan..."
bandit -r .

echo "All quality gates passed."
