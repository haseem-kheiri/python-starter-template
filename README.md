# Python Starter Template

Production-ready starter for Python projects with Ruff, mypy, pytest, coverage, dependency audit, and security scanning.

## What is included

- Formatting and linting: Ruff
- Type checking: mypy
- Tests: pytest
- Coverage gate: pytest-cov
- Dependency CVE scan: pip-audit
- Security static analysis: bandit
- Cross-platform quality scripts: PowerShell and bash

## Quick start

1. Install uv:
   - `pip install uv`
2. Create and activate a virtual environment:
   - `uv venv .venv`
   - Windows: `.venv\\Scripts\\activate`
   - macOS/Linux: `source .venv/bin/activate`
3. Install dependencies:
   - `uv pip install -r requirements-dev.txt`
4. Run all quality gates:
   - Windows: `.\\scripts\\quality-gates.ps1`
   - macOS/Linux: `./scripts/quality-gates.sh`

## Notes

- `requirements.txt` is runtime-only.
- `requirements-dev.txt` imports runtime plus tools.
- `tools.requirements.txt` is the shared tools baseline.
- VS Code users should open this folder as the workspace root.
