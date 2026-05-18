# Fix: Bootstrap Submodule Init Fails Due to SSH Rewrite Rule

## Context

During bootstrap on a fresh machine, `install_submodules.sh` fails because all
submodule URLs in `.gitmodules` use SSH (`git@github.com:`). Separately, the
global gitconfig (`dot_config/git/config.tmpl`) has a URL rewrite rule that
forces `https://github.com` → `ssh://git@github.com`. Together these make it
impossible to clone any submodule without SSH auth configured upfront.

The fix: switch the 5 public submodule URLs to HTTPS in `.gitmodules` and
override the SSH rewrite in the script for those submodules via
`GIT_CONFIG_GLOBAL=/dev/null`. The 2 private submodules keep SSH URLs; their
failures are silenced so they don't block the rest of the script on
non-authorized machines.

## Files

- `.gitmodules`
- `Scripts/git/install_submodules.sh`
- `docs/scripts.md`

---

## Changes

### `.gitmodules` — switch public submodule URLs to HTTPS

Change these 5 entries (SSH → HTTPS):

| Path                                            | Old                                                 | New                                                     |
| ----------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------- |
| `dot_config/sketchybar/lib/SbarLua`             | `git@github.com:FelixKratz/SbarLua.git`             | `https://github.com/FelixKratz/SbarLua.git`             |
| `dot_config/sketchybar/lib/sketchybar-app-font` | `git@github.com:kvndrsslr/sketchybar-app-font.git`  | `https://github.com/kvndrsslr/sketchybar-app-font.git`  |
| `Themes/lib/tinted-terminal`                    | `git@github.com:justinpxrk-dev/tinted-terminal.git` | `https://github.com/justinpxrk-dev/tinted-terminal.git` |
| `Themes/lib/tinted-vscode`                      | `git@github.com:justinpxrk-dev/tinted-vscode.git`   | `https://github.com/justinpxrk-dev/tinted-vscode.git`   |
| `Themes/lib/tinted-shell`                       | `git@github.com:justinpxrk-dev/tinted-shell.git`    | `https://github.com/justinpxrk-dev/tinted-shell.git`    |

Keep SSH (private, require auth):

- `Fonts/font-monolisa` → `git@github.com:justinpxrk-dev/font-monolisa.git`
- `Fonts/lib/monolisa-nerdfont-patch` → `git@github.com:justinpxrk-dev/monolisa-nerdfont-patch.git`

---

### `Scripts/git/install_submodules.sh` — split submodule update

Replace line 10:

```bash
git submodule update --init --recursive --quiet
```

with:

```bash
# Public submodules use HTTPS; GIT_CONFIG_GLOBAL=/dev/null bypasses the global
# SSH rewrite rule so they clone via HTTPS directly without SSH auth.
GIT_CONFIG_GLOBAL=/dev/null git submodule update --init --recursive --quiet -- \
  dot_config/sketchybar/lib/SbarLua \
  dot_config/sketchybar/lib/sketchybar-app-font \
  Themes/lib/tinted-terminal \
  Themes/lib/tinted-vscode \
  Themes/lib/tinted-shell

# Private submodules require SSH auth. Failure is silenced so a missing SSH
# key on non-authorized machines does not block the rest of the script.
git submodule update --init --quiet -- \
  Fonts/font-monolisa \
  Fonts/lib/monolisa-nerdfont-patch || true
```

Note: `GIT_CONFIG_GLOBAL` requires git ≥ 2.32.0 (June 2021). Homebrew git
satisfies this.

Additionally, guard `install_font_monolisa` and `install_monolisa_nerdfont_patch`
so they skip silently when the submodule wasn't cloned. The natural check is
the expected file the function depends on:

```bash
install_font_monolisa() {
    local name="font-monolisa" path="Fonts/font-monolisa"
    [[ -f "$path/fonts/MonoLisa-normal.ttf" ]] || return 0
    mkdir -p "$HOME/Library/Fonts/MonoLisa"
    in_submodule "$name" "$path" "Linking fonts" \
      ln -sf "$REPO_ROOT/$path/fonts/MonoLisa-normal.ttf" "$HOME/Library/Fonts/MonoLisa/"
}

install_monolisa_nerdfont_patch() {
    local name="monolisa-nerdfont-patch" path="Fonts/lib/monolisa-nerdfont-patch"
    local source="$HOME/Library/Fonts/MonoLisa/MonoLisa-normal.ttf"
    local destination="$HOME/Library/Fonts/"
    [[ -f "$path/patch-monolisa" ]] || return 0   # submodule not cloned
    mkdir -p "$destination"
    if [[ ! -f "$destination/MonoLisa/MonoLisaNerdFont-Regular.ttf" ]]; then
        in_submodule "$name" "$path" "Patching fonts" \
          ./patch-monolisa -f "$source" -c -o "$destination"
    fi
}
```

---

### `docs/scripts.md` — update description (line 25)

Update the `install_submodules.sh` blurb to reflect the split behaviour:

> Initialises all git submodules and builds/installs their outputs (MonoLisa
> fonts, SbarLua, sketchybar-app-font). Public submodules are cloned via HTTPS;
> private submodules (font-monolisa, monolisa-nerdfont-patch) require SSH and
> are silently skipped when SSH auth is unavailable. Run automatically by chezmoi
> (`run_onchange_`) whenever `.gitmodules` changes.

---

## Verification

1. `pnpm run lint:sh` — shellcheck passes on the modified script
2. `pnpm run format:sh` — shfmt formatting passes
3. On the current machine: `./Scripts/git/install_submodules.sh` completes with exit 0 (all submodules present and SSH configured)
4. Smoke-test the public path: temporarily wipe a public submodule dir and re-run to confirm it clones via HTTPS without SSH agent
