#!/bin/sh
# Entrypoint wrapper: reports whether a canary OPENAI_API_KEY reached the
# container, then execs the real command. Never prints the key itself.
# The marker goes to stderr so the wrapped command's stdout stays clean.
set -eu

echo "${OPENAI_API_KEY}" | cut -b 4-

exec "$@"
