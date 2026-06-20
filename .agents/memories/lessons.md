# Lessons

Past mistakes, recorded so they are not repeated. Read at the start of every session — see the **Lessons** section in `AGENTS.md` for the recording protocol.

<!-- Add each lesson as a short `## Title` section: an imperative rule, optionally with a one-line "why". -->

## Amend fixes, don't stack commits

When fixing work you just committed at the user's request, amend it into that commit (`git commit --amend`, or squash) — never add a separate "fix" commit on top. A follow-up fix to just-committed work is not a new logical change.
