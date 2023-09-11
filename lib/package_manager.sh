# shellcheck shell=bash

PACKAGE_MANAGER=""

if [ -n "$NISH_DRY_RUN" ]; then 
    NISH_DRY_RUN="echo"
fi

if [ -f "package.json" ]; then
    PACKAGE_MANAGER="$(jq -r 'if has("packageManager") then .packageManager | split("@") | .[0] else "" end' < package.json)"
    [ -n "$PACKAGE_MANAGER" ] && return
fi

[ -f "pnpm-lock.yaml" ] && PACKAGE_MANAGER="pnpm"
[ -f "bun.lockb" ] && PACKAGE_MANAGER="bun"
[ -f "yarn.lock" ] && PACKAGE_MANAGER="yarn"
[ -f "package-lock.json" ] && PACKAGE_MANAGER="npm"
[ "$PACKAGE_MANAGER" != "" ] && return

if ! command -v gum &> /dev/null; then
    echo "Could not determine package manager"
    exit 1
fi

if ! PACKAGE_MANAGER="$(gum choose "pnpm" "bun" "yarn" "npm" --header="Which package manager to use?")"; then
    echo "Could not read choice from gum"
    exit 1
fi
