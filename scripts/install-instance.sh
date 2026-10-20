#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  printf 'Usage: %s <instance-name> [plugin-file-name]\n' "$0" >&2
  exit 2
fi

instance="$1"
plugin_file="${2:-}"
if [[ ! "${instance}" =~ ^[A-Za-z0-9_-]+$ ]]; then
  printf 'Invalid instance name: %s (use ASCII letters, digits, - and _)\n' "${instance}" >&2
  exit 2
fi

if [[ -n "${plugin_file}" && ! "${plugin_file}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  printf 'Invalid plugin file name: %s\n' "${plugin_file}" >&2
  exit 2
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
prefix="${CBAR_PREFIX:-$HOME/.local}"
app_dir="${prefix}/share/applications"
binary_path="${prefix}/bin/cbar"
desktop_template="${repo_root}/data/io.github.alexprates.CBar.desktop.in"
config_target="${HOME}/.config/cbar/config-${instance}.json"
desktop_target="${app_dir}/io.github.alexprates.CBar.${instance}.desktop"

mkdir -p "${app_dir}"

sed \
  -e "s|__CBAR_EXEC__|${binary_path} --instance ${instance}|g" \
  -e "s|^Name=cbar$|Name=cbar (${instance})|" \
  "${desktop_template}" > "${desktop_target}"

if [[ -n "${plugin_file}" ]]; then
  if [[ -e "${config_target}" ]]; then
    printf 'Config already exists, left unchanged: %s\n' "${config_target}"
  else
    mkdir -p "$(dirname "${config_target}")"
    printf '{\n  "enabled_plugins": [\n    "%s"\n  ]\n}\n' "${plugin_file}" > "${config_target}"
    printf 'Config: %s\n' "${config_target}"
  fi
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${app_dir}" || true
fi

printf 'Installed cbar instance: %s\n' "${instance}"
printf 'Desktop entry: %s\n' "${desktop_target}"
if [[ -z "${CBAR_SKIP_PANEL_HINT:-}" ]]; then
  printf 'Add "cbar (%s)" to the panel from COSMIC settings, or run scripts/add-plugin.sh.\n' "${instance}"
fi
