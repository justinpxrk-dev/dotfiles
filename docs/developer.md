# developer.md

Instructions for setting up and configuring developer tools.

## Requirements

- `mise`
- `uv`

## Setup

Install all tools managed by `mise`, install Node.js packages, and sync Python dev dependencies. The `pnpm install` step also runs `lefthook install` via the `prepare` script, which sets up the pre-commit hook. The `uv sync --dev` step creates the virtual environment at `.venv/` and installs all Python dependencies into it.

```sh
mise install
pnpm install
uv sync --dev
```

## Usage

Format and lint commands are available via `pnpm`. See [AGENTS.md](agents/AGENTS.md) for the full command reference.
