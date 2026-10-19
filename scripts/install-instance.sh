#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s <instance-name>\n' "$0" >&2
  exit 2
fi

instance="$1"
if [[ ! "${instance}" =~ ^[A-Za-z0-9_-]+$ ]]; then
  printf 'Invalid instance name: %s (use ASCII letters, digits, - and _)\n' "${instance}" >&2
  exit 2
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
prefix="${CBAR_PREFIX:-$HOME/.local}"
app_dir="${prefix}/share/applications"
binary_path="${prefix}/bin/cbar"
desktop_template="${repo_root}/data/io.github.alexprates.CBar.desktop.in"
desktop_target="${app_dir}/io.github.alexprates.CBar.${instance}.desktop"

mkdir -p "${app_dir}"

sed \
  -e "s|__CBAR_EXEC__|${binary_path} --instance ${instance}|g" \
  -e "s|^Name=cbar$|Name=cbar (${instance})|" \
  "${desktop_template}" > "${desktop_target}"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${app_dir}" || true
fi

printf 'Installed cbar instance: %s\n' "${instance}"
printf 'Desktop entry: %s\n' "${desktop_target}"
printf 'Config: ~/.config/cbar/config-%s.json (created when plugins are selected in the popup)\n' "${instance}"
