# Developer

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
pnpm run check           # Run all checks: format:check + lint (mirrors CI and the pre-commit hook)
pnpm run fix             # Auto-fix everything fixable: lint fixes (ruff --fix, markdownlint --fix) then format
pnpm run format          # Format all (Markdown via prettier, shell via shfmt, Lua via stylua, Python via ruff)
pnpm run format:check    # Check formatting without writing
pnpm run lint            # Lint Markdown (markdownlint), shell (shellcheck), Lua (lua-language-server), and Python (ruff, pyright)
```

Individual formatters:

```sh
pnpm run format:md / format:sh / format:lua / format:py
pnpm run lint:sh / lint:lua / lint:py
```

shfmt uses `.editorconfig` for ignore rules — submodule and third-party paths are excluded there. The `--apply-ignore` flag must be passed for shfmt to respect them.

## CI

GitHub Actions runs `format:check` and `lint` on every push and pull request to any branch. The workflow mirrors local setup: mise installs all tools, then `pnpm install --frozen-lockfile` and `uv sync --dev` install package dependencies before running checks.

Two deploy workflows run a real `chezmoi apply` against the macOS runner using the branch under test as the source dir (checked out and symlinked to `~/.local/share/chezmoi`):

- `deploy-public-macos.yml` — runs on every push and pull request (any branch), `workflow_dispatch`, and a staggered 12-hour schedule (`cron: 3 3,15 * * *`). No secrets, so fork PRs are safe; private submodules fail silently.
- `deploy-authenticated-macos.yml` — runs on every push (any branch), `workflow_dispatch`, and a staggered 12-hour schedule (`cron: 7 7,19 * * *`, offset from the public deploy to avoid runner contention). Uses `webfactory/ssh-agent` with deploy keys for private submodules. `pull_request` is intentionally excluded so deploy-key secrets are never exposed to fork PRs.

`zsh-benchmark-startup.yml` measures shell startup time on the macOS runner. It runs on `workflow_dispatch` and on push/pull request when `dot_config/zsh/**` changes: it applies the branch's dotfiles, warms up the shell, benchmarks startup, then evaluates and reports the result.

## Worktrees

When working in a worktree, some tools require per-path trust or registration before they function. Run any required setup after creating a worktree, and clean up before removing it — the `/merge` skill handles cleanup automatically.

**mise** — trust the config before any mise command, then install tools and bootstrap Node packages using the mise-managed PATH:

```sh
mise trust                          # required before mise install or mise run
mise install                        # install tools
mise exec -- pnpm install           # bootstrap lefthook and other PATH-dependent tools
mise trust --untrust mise.toml      # on exit (handled by /merge)
```
