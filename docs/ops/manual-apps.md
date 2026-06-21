# manual-apps.md

GUI apps installed by hand — dragged from a DMG or run from a `.pkg` — rather than through Homebrew or the Mac App Store. Nothing replays these on a fresh machine, so they have to be re-downloaded and reinstalled by hand; this is the list to walk after `brew bundle` and `mas` on a new setup.

Everything else in `/Applications` is tracked elsewhere and is deliberately left out of the table below:

- **Homebrew casks** — declared in `dot_Brewfile`, reinstalled with `brew bundle --file ~/.Brewfile`. Audit with `brew list --cask`. Includes pkg-based casks (Logi Tune, Zoom, SF Symbols) that install through macOS's installer but are still Homebrew-managed.
- **Mac App Store** — reinstalled with `mas`. Audit with `mas list`; currently Copilot, Dynamic wallpaper, and Flow.
- **Apple system apps** — Safari and friends ship with macOS.

## Apps

| App          | Version | Bundle ID                     | Signed by (Team ID)        | Source                                                                                                                                |
| ------------ | ------- | ----------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| MacParakeet  | 0.6.19  | `com.macparakeet.MacParakeet` | Daniel Moon (`FYAF2ZD7RM`) | [macparakeet.com](https://macparakeet.com) — notarized DMG also on [GitHub releases](https://github.com/moona3k/macparakeet/releases) |
| pCloud Drive | 4.0.12  | `com.pcloud.pcloud.macos`     | PCLOUD LTD (`KSTWHH4JHP`)  | [pcloud.com](https://www.pcloud.com)                                                                                                  |

Versions are what was installed as of 2026-06-06 — a record, not a pin; they drift as the apps self-update.

## Re-auditing

Run this after installing or removing a hand-downloaded app. It prints every `/Applications/*.app` that carries no App Store receipt and whose name doesn't match a Homebrew cask token — i.e. the manual ones:

```sh
tokens=$(mktemp)
brew list --cask | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9\n' | sort -u > "$tokens"
for a in /Applications/*.app; do
  [ -d "$a/Contents/_MASReceipt" ] && continue          # skip Mac App Store apps
  name=$(basename "${a%.app}")
  norm=$(printf '%s' "$name" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9')
  matched=
  while IFS= read -r t; do case "$norm" in "$t"*) matched=1; break;; esac; done < "$tokens"
  [ -n "$matched" ] && continue                          # skip Homebrew casks (incl. pkg-based)
  printf '%s\n' "$name"
done
rm -f "$tokens"
```

`Safari` also prints — it's the lone Apple system app in `/Applications` with no cask token; ignore it. Anything else the script prints that isn't already in the table is a new manual app to add.
