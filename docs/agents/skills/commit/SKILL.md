Before committing, review all pending changes and update any relevant documentation to reflect the new state. This includes `docs/agents/AGENTS.md`, other files in `docs/`, and any READMEs. Also review changed code and add missing documentation comments (purpose, parameters, return values) and inline WHY comments. Apply all updates as part of the same commit. Do not ask for confirmation — just commit.

## Commit Message Format

```
[tool1,tool2] Title Case Summary

- Bullet describing change one
- Bullet describing change two
```

## Rules

- **Tools**: lowercase, comma-separated, no spaces — derived from what files were changed (e.g. `zsh`, `nvim`, `python`, `git`, `sketchybar`)
- **Title**: title case, imperative mood (e.g. "Add", "Fix", "Remove", "Update")
- **Body**: one bullet per logical change; omit entirely if the title is self-explanatory
- Review all changes for documentation impact before staging
- Update `docs/agents/AGENTS.md`, `docs/`, and READMEs as needed to reflect the new state
- Run `git add -A` first, then commit
- Do not include any co-author or attribution lines

## Examples

```
[zsh] Suppress Login Message
```

```
[python,pyright] Enable Strict Type Checking

- Set strict mode in pyproject.toml
- Resolved all resulting type errors
```

```
[nvim,lua] Add Telescope Keybindings

- Bound <leader>ff to find_files
- Bound <leader>fg to live_grep
```
