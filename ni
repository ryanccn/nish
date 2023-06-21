#!/bin/bash
set -euo pipefail

exec_path="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1091
. "$exec_path/lib/package_manager.sh"

if [ $# -lt 1 ]; then
  $PACKAGE_MANAGER install
else
  if [ "$PACKAGE_MANAGER" = "npm" ]; then
    "$PACKAGE_MANAGER" install "$1"
  else
    "$PACKAGE_MANAGER" add "$1"
  fi
fi
