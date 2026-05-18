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

## Formatting and Linting

```sh
pnpm run format          # Format all (Markdown via prettier, shell via shfmt, Lua via stylua, Python via ruff)
pnpm run format:check    # Check formatting without writing
pnpm run lint            # Lint shell (shellcheck), Lua (lua-language-server), and Python (ruff, pyright)
```

Individual formatters:

```sh
pnpm run format:md / format:sh / format:lua / format:py
pnpm run lint:sh / lint:lua / lint:py
```

shfmt uses `.editorconfig` for ignore rules — submodule and third-party paths are excluded there. The `--apply-ignore` flag must be passed for shfmt to respect them.

## CI

GitHub Actions runs `format:check` and `lint` on every push and pull request to `main`. The workflow mirrors local setup: mise installs all tools, then `pnpm install --frozen-lockfile` and `uv sync --dev` install package dependencies before running checks.

## Worktrees

When working in a worktree, some tools require per-path trust or registration before they function. Run any required setup after creating a worktree, and clean up before removing it — the `/merge` skill handles cleanup automatically.

**mise** — trust the config before any mise command, then install tools and bootstrap Node packages using the mise-managed PATH:

```sh
mise trust                          # required before mise install or mise run
mise install                        # install tools
mise exec -- pnpm install           # bootstrap lefthook and other PATH-dependent tools
mise trust --untrust mise.toml      # on exit (handled by /merge)
```
