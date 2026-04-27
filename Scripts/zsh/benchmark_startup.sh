#!/usr/bin/env bash

hyperfine --warmup 10 --runs 200 'zsh -i -l -c exit'
