# Starter Setup Notes

## Optional dmypy path setting

If VS Code reports dmypy missing, set one of these in `.vscode/settings.json`.

Windows:

```json
{
  "mypy.dmypyExecutable": "${workspaceFolder}/.venv/Scripts/dmypy.exe",
  "mypy-type-checker.dmypyExecutable": "${workspaceFolder}/.venv/Scripts/dmypy.exe"
}
```

macOS/Linux:

```json
{
  "mypy.dmypyExecutable": "${workspaceFolder}/.venv/bin/dmypy",
  "mypy-type-checker.dmypyExecutable": "${workspaceFolder}/.venv/bin/dmypy"
}
```
