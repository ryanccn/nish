# shellcheck shell=bash

PACKAGE_MANAGER=""

package_json_package_manager=""

if [ -f "package.json" ]; then
  package_json_package_manager="$(jq -r '.packageManager | split("@") | .[0]' < package.json)"
fi

if [ -n "$package_json_package_manager" ]; then
  PACKAGE_MANAGER="$package_json_package_manager"
fi

if [ -z "$PACKAGE_MANAGER" ]; then
  if [ -f "pnpm-lock.yaml" ]; then PACKAGE_MANAGER="pnpm"; fi
  if [ -f "yarn.lock" ]; then PACKAGE_MANAGER="yarn"; fi
  if [ -f "package-lock.json" ]; then PACKAGE_MANAGER="npm"; fi
fi

if [ -z "$PACKAGE_MANAGER" ]; then
  if [[ "$(command -v gum)" ]]; then
    PACKAGE_MANAGER="$(gum choose "pnpm" "yarn" "npm" --header="Which package manager to use?")"
  else
    echo "Could not determine package manager"
    exit 1
  fi
fi
