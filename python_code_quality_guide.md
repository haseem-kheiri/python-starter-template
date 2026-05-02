# Python Code Quality and Testing Guide

This guide summarizes practical setup patterns for formatting, linting, type checking, and testing in Python projects.

## Project Root File Locations

Assume the project root is the folder you opened in VS Code for this repository.

- Tool config (shared across CLI, CI, editors): `pyproject.toml`
- VS Code workspace settings: `.vscode/settings.json`

Quick mental model:

- If the guide says "configure in pyproject.toml", edit the file at the project root.
- If the guide says "configure in .vscode/settings.json", edit the file under the `.vscode` folder at the project root.

Starter template locations for new projects:

- `./pyproject.toml`
- `./.vscode/settings.json`

## 0. Environment and Package Management with uv

uv is a fast, modern package manager and environment tool for Python.

- Install uv (if not already available):
  - `pip install uv`
- Create a virtual environment:
  - `uv venv .venv`
  - Optional Python version: `uv venv .venv --python 3.12`
- Activate the environment:
  - Windows: `.venv\Scripts\activate`
  - macOS/Linux: `source .venv/bin/activate`
- Install packages:
  - `uv pip install ruff mypy pytest`

## Configuration Strategy (Generic)

Use two configuration layers:

- `pyproject.toml`
  - Tool behavior and project standards.
  - Applies across terminal, CI, and editors.
- `.vscode/settings.json`
  - VS Code workflow behavior.
  - Controls save actions, default formatter, and test integration.

Rule of thumb:

- Shared standards go in `pyproject.toml`.
- Editor workflow ergonomics go in `.vscode/settings.json`.

## Dependency File Policy for New Projects

Default approach:

- Use `pyproject.toml` as the primary dependency and tool-configuration source.

For development tools in this guide (`ruff`, `mypy`, `pytest`, `pytest-cov`, `pip-audit`, `bandit`):

- Keep them in your primary dependency source.
- If your team needs pip-style files, keep these tools in a reusable `tools.requirements.txt` file.

When to add `requirements.txt`:

- A deployment platform or CI pipeline requires `pip install -r requirements.txt`.
- Team workflows or templates in your organization still depend on `requirements.txt`.

Recommended split when using requirements files:

- `requirements.txt`: runtime dependencies only.
- `requirements-dev.txt`: developer tooling and test dependencies.
- `tools.requirements.txt`: shared developer tooling baseline for new projects.

Starter `requirements.txt`:

```txt
# Runtime dependencies for this project.
# Add runtime modules here, one per line.
```

Starter `tools.requirements.txt`:

```txt
ruff
mypy
pytest
pytest-cov
pip-audit
bandit
```

Starter `requirements-dev.txt` importing runtime and tools baselines:

```txt
-r requirements.txt
-r tools.requirements.txt
```

If your workflow requires importing tools from `requirements.txt`, it also works:

```txt
-r tools.requirements.txt
```

Use that pattern only when you intentionally want tooling installed in runtime images/environments.

Important:

- If both files exist, declare one source of truth and generate the other to avoid drift.

## 1. Ruff: Linting, Import Sorting, and Formatting

Ruff provides fast linting, auto-fix, import sorting, and formatting.

- Install: `uv pip install ruff`
- Lint: `ruff check .`
- Fix and sort imports: `ruff check . --fix`
- Format: `ruff format .`

### Ruff in pyproject.toml

```toml
[tool.ruff.format]
preview = true
```

Why `preview = true`:

- Enables Ruff preview formatting behavior (including Markdown-format-related preview features).

### Ruff in .vscode/settings.json

```json
{
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff"
  },
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.ruff": "explicit",
    "source.organizeImports.ruff": "explicit"
  }
}
```

Notes:

- `explicit` runs on manual save (for example, Ctrl+S).
- It does not run on Auto Save.

Black note:

- You do not need Black when using Ruff formatter.
- Keep Black only if an existing team/project standard already requires it.

## 2. mypy (Type Checking)

mypy checks static types based on type hints.

- Install: `uv pip install mypy`
- Run: `mypy .`

### mypy in pyproject.toml

```toml
[tool.mypy]
python_version = "3.12"
warn_unused_configs = true
disallow_untyped_defs = true
```

### mypy in .vscode/settings.json

```json
{
  "mypy-type-checker.args": [
    "--config-file",
    "${workspaceFolder}/pyproject.toml"
  ]
}
```

Note:

- This VS Code setting is used when the mypy VS Code extension is installed.

### dmypy (mypy daemon) in .vscode/settings.json

If VS Code reports that `dmypy` is missing, point the extension to the virtual environment executable.

Windows (`.venv\Scripts\dmypy.exe`):

```json
{
  "mypy.dmypyExecutable": "${workspaceFolder}/.venv/Scripts/dmypy.exe",
  "mypy-type-checker.dmypyExecutable": "${workspaceFolder}/.venv/Scripts/dmypy.exe"
}
```

macOS/Linux (`.venv/bin/dmypy`):

```json
{
  "mypy.dmypyExecutable": "${workspaceFolder}/.venv/bin/dmypy",
  "mypy-type-checker.dmypyExecutable": "${workspaceFolder}/.venv/bin/dmypy"
}
```

Notes:

- Keep both keys for compatibility across mypy extension variants.
- Ensure mypy is installed in the same environment: `uv pip install mypy`.

## 3. Testing with pytest (Recommended Default)

For new projects, use pytest as the default test framework.

- Install: `uv pip install pytest`
- Run: `pytest`

### pytest in pyproject.toml

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
```

Note:

- `tests` is a generic default for new projects. Change it if your repository uses a different layout.

### pytest in .vscode/settings.json

```json
{
  "python.testing.pytestEnabled": true,
  "python.testing.unittestEnabled": false,
  "python.testing.pytestArgs": [
    "."
  ]
}
```

Optional note:

- Keep unittest only when required by an existing codebase or a strict standard-library-only policy.
- Even then, choose one framework in VS Code test settings at a time.

### pytest-cov (Coverage)

Why include it:

- Enforces minimum test coverage in CI (for example, fail below 85%).

Where to configure:

- `pyproject.toml`: optional, via pytest `addopts`.
- `.vscode/settings.json`: no dedicated setting required.

Optional `pyproject.toml` example:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "--cov=. --cov-fail-under=85"
```

If you prefer coverage only in CI, keep `addopts` out of `pyproject.toml` and run:

```bash
pytest --cov=. --cov-fail-under=85
```

## 4. Recommended VS Code Extensions

- Python (Microsoft)
- Pylance
- Ruff
- Python Test Explorer support (optional)

## 5. Typical Workflow

1. Write code and tests.
2. Save to apply formatter/lint actions.
3. Run `ruff check . --fix` and `ruff format .`.
4. Run tests with `pytest`.
5. Run `mypy .` when type checks are required.

## Production Readiness Baseline

This guide provides a strong code-quality foundation, but production readiness usually needs these extra gates:

1. Dependency safety and repeatability
- Pin dependency versions for CI and release builds.
- Run `pip-audit` in CI to detect known vulnerable packages.

2. Automated quality gates in CI
- Fail builds when any of these commands fail:
  - `ruff check .`
  - `ruff format --check .`
  - `mypy .`
  - `pytest --cov=. --cov-fail-under=85`

3. Security linting
- Run `bandit -r .` in CI (scope/exclusions can be tuned per project).

4. Team consistency
- Add pre-commit hooks (recommended) so checks run before code reaches CI.

Tool configuration notes for security/dependency checks:

- `pip-audit`
  - Why include it: checks installed dependencies for known vulnerabilities.
  - `pyproject.toml`: no baseline entry required.
  - `.vscode/settings.json`: no dedicated setting required.
  - Typical usage: run in CI with `pip-audit`.

- `bandit`
  - Why include it: static security scan of Python code.
  - `pyproject.toml`: no baseline entry required in this template.
  - `.vscode/settings.json`: no dedicated setting required.
  - Typical usage: run in CI with `bandit -r .`.

---

Adopting these patterns keeps tool behavior consistent across local development, VS Code, and CI.

## 6. New Project Quick Start (Copy/Paste Baseline)

Use this sequence for new repositories.

1. Install uv

```bash
pip install uv
```

2. Create and activate virtual environment

```bash
uv venv .venv
```

Windows:

```powershell
.venv\Scripts\activate
```

macOS/Linux:

```bash
source .venv/bin/activate
```

3. Create requirements files

`requirements.txt`:

```txt
# Runtime dependencies for this project.
# Add runtime modules here, one per line.
```

`tools.requirements.txt`:

```txt
ruff
mypy
pytest
pytest-cov
pip-audit
bandit
```

`requirements-dev.txt`:

```txt
-r requirements.txt
-r tools.requirements.txt
```

4. Install modules from requirements files

```bash
uv pip install -r requirements-dev.txt
```

5. Create `pyproject.toml`

```toml
[tool.ruff.format]
preview = true

[tool.mypy]
python_version = "3.12"
warn_unused_configs = true
disallow_untyped_defs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
```

Optional coverage default (if you want coverage on every pytest run):

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "--cov=. --cov-fail-under=85"
```

Notes:

- `pytest-cov` can be configured via `addopts` (above) or passed only in CI/CLI.
- `pip-audit` and `bandit` are typically run from CLI/CI and do not require baseline `pyproject.toml` or `.vscode/settings.json` entries.

6. Create `.vscode/settings.json` (Windows example)

```json
{
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff"
  },
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.ruff": "explicit",
    "source.organizeImports.ruff": "explicit"
  },
  "mypy-type-checker.args": [
    "--config-file",
    "${workspaceFolder}/pyproject.toml"
  ],
  "mypy.dmypyExecutable": "${workspaceFolder}/.venv/Scripts/dmypy.exe",
  "mypy-type-checker.dmypyExecutable": "${workspaceFolder}/.venv/Scripts/dmypy.exe",
  "python.testing.pytestEnabled": true,
  "python.testing.unittestEnabled": false,
  "python.testing.pytestArgs": [
    "."
  ]
}
```

For macOS/Linux, replace `.venv/Scripts/dmypy.exe` with `.venv/bin/dmypy`.

7. Reload VS Code

- Open Command Palette and run: `Developer: Reload Window`.

8. Verify production baseline locally

```bash
ruff check .
ruff format --check .
mypy .
pytest --cov=. --cov-fail-under=85
pip-audit
bandit -r .
```
