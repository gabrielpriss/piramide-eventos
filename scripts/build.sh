#!/usr/bin/env bash
# Alias legado — use scripts/build-dark.sh
exec "$(dirname "$0")/build-dark.sh" "$@"
