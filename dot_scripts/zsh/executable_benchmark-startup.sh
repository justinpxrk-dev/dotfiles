#!/usr/bin/env bash
set -euo pipefail

hyperfine --warmup 50 --runs 200 'zsh -i -l -c exit'
