# Developer

Instructions for setting up and configuring developer tools.

## Requirements

- `mise`

## Setup

Mise manages tool versions and repository tasks. pnpm manages the Node dependencies declared in `package.json`. Run the setup task to prepare the repository:

```sh
mise run setup
```

By default, `mise run` automatically installs missing tools declared in the `[tools]` section of `mise.toml` before executing a task. The `setup` task then installs the locked Node dependencies and registers the Lefthook pre-commit hook.

## Formatting and Linting

```sh
mise run check           # Run all checks: format:check + lint (mirrors CI and the pre-commit hook)
mise run fix             # Auto-fix Markdown lint issues, then format all files
mise run format          # Format all (Markdown via prettier, shell via shfmt, Lua via stylua)
mise run format:check    # Check formatting without writing
mise run lint            # Lint Markdown (markdownlint), shell (shellcheck), and Lua (lua-language-server)
```

Individual formatters:

```sh
mise run format:md / format:sh / format:lua
mise run lint:md / lint:sh / lint:lua
```

shfmt uses `.editorconfig` for ignore rules — submodule and third-party paths are excluded there. The `--apply-ignore` flag must be passed for shfmt to respect them.

Tasks are defined in `mise.toml` and run from the repository root, including when invoked from a subdirectory. Composite tasks preserve their command order: `fix` finishes Markdown lint fixes before formatting, and `check` finishes format checks before linting. Use `mise tasks ls` to list the available tasks. To add or update Node packages, use pnpm directly; package versions remain in `package.json` and `pnpm-lock.yaml`.

## Zed

`.zed/settings.json` configures this repository's format-on-save behavior: CSS, HTML, JavaScript, JSON, Markdown, and YAML use the project's Prettier dependency; Lua uses StyLua; shell scripts use shfmt. Commands run through `mise exec` to use the tools declared in `mise.toml`. The formatters receive the buffer on stdin and its path for configuration and ignore-file discovery, reusing `.editorconfig`, `.prettierignore`, and `.styluaignore`.

Use `task: spawn` to run `dotfiles: check`, `dotfiles: lint`, or `dotfiles: fix`. These tasks save open buffers first, then invoke `mise run check`, `mise run lint`, or `mise run fix`. Lint results appear in the task terminal.

The `.zed/` directory is committed for this project's use and excluded from chezmoi deployment. Personal Zed settings live in `dot_config/zed/settings.json`, which chezmoi applies to `~/.config/zed/settings.json`.

## CI

The Format/Lint workflow runs on pushes to `main` and pull requests targeting `main`. Both jobs run `mise run deps:install` to install the locked Node dependencies, then run `mise run format:check` or `mise run lint`. The Lefthook pre-commit hook runs those same checks in parallel.

Two deploy workflows run a real `chezmoi apply` against the macOS runner using the branch under test as the source dir (checked out and symlinked to `~/.local/share/chezmoi`):

- `deploy-public-macos.yml` — runs on pushes to `main`, pull requests targeting `main`, `workflow_dispatch`, and a staggered 12-hour schedule (`cron: 3 3,15 * * *`). No secrets, so fork PRs are safe; private submodules fail silently.
- `deploy-authenticated-macos.yml` — runs on every push (any branch), `workflow_dispatch`, and a staggered 12-hour schedule (`cron: 7 7,19 * * *`, offset from the public deploy to avoid runner contention). Uses `webfactory/ssh-agent` with deploy keys for private submodules. `pull_request` is intentionally excluded so deploy-key secrets are never exposed to fork PRs.

All three macOS workflows run `brew update` before `chezmoi apply`. The startup benchmark performs this setup only when its benchmark gate is enabled.

`zsh-benchmark-startup.yml` measures shell startup time on the macOS runner. It runs on `workflow_dispatch`, a 12-hour schedule (`cron: 9 9,21 * * *`), pushes to `main`, and pull requests targeting `main`. For push/pull request events, it benchmarks only when startup-relevant files change — the zsh config plus everything that shapes the benchmarked HOME (`dot_zshenv.tmpl`, `dot_config/git/**`, `dot_Brewfile`, `.chezmoiscripts/**`, the workflow itself). Manual and scheduled runs always benchmark. It applies the branch's dotfiles, warms up the shell and verifies every antidote plugin actually cloned (a failed clone would benchmark a degraded, artificially fast shell), then gates hyperfine's min against `THRESHOLD_MS` — runner noise is strictly additive, so the min tracks config cost where the mean tracks VM contention.

## Worktrees

When working in a worktree, some tools require per-path trust or registration before they function. Run any required setup after creating a worktree, and clean up before removing it.

**mise** — trust the worktree's config, then run setup to install tools, Node dependencies, and Git hooks:

```sh
mise trust                          # required before running project tasks
mise run setup                      # install tools, Node dependencies, and Git hooks
mise trust --untrust mise.toml      # on exit, before removing the worktree
```

Tear the worktree down manually once its branch is merged:

```sh
git worktree remove <path>          # run from the main checkout, not the worktree
git branch -d <branch>
```
