$ErrorActionPreference = "Stop"

Write-Host "Running Ruff lint..."
ruff check .

Write-Host "Running Ruff format check..."
ruff format --check .

Write-Host "Running mypy..."
mypy .

Write-Host "Running pytest with coverage threshold..."
pytest --cov=. --cov-fail-under=85

Write-Host "Running dependency vulnerability scan..."
pip-audit

Write-Host "Running Bandit security scan..."
bandit -r .

Write-Host "All quality gates passed." -ForegroundColor Green
