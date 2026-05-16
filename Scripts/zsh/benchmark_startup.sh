#!/usr/bin/env bash

hyperfine --warmup 50 --runs 200 'zsh -i -l -c exit'
