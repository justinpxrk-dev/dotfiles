# developer.md

Instructions for setting up and configuring developer tools.

## Requirements

- `mise`
- `uv`

## Setup

Install all tools managed by `mise`, install Node.js packages, and sync Python dev dependencies:

```sh
mise install
pnpm install
uv sync --dev
```

## Usage

Format and lint commands are available via `pnpm`. See [AGENTS.md](agent/AGENTS.md) for the full command reference.
