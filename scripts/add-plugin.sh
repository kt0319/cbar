#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  printf 'Usage: %s <plugin-file-name> [start|end]\n' "$0" >&2
  exit 2
fi

plugin_file="$1"
side="${2:-end}"
if [[ "${side}" != "start" && "${side}" != "end" ]]; then
  printf 'Invalid side: %s (use start or end)\n' "${side}" >&2
  exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
plugin_dir="${CBAR_PLUGIN_DIR:-$HOME/.config/cbar/plugins}"
wings_file="${CBAR_PANEL_WINGS_FILE:-$HOME/.config/cosmic/com.system76.CosmicPanel.Panel/v1/plugins_wings}"

if [[ ! -x "${plugin_dir}/${plugin_file}" ]]; then
  printf 'Plugin not found or not executable: %s/%s\n' "${plugin_dir}" "${plugin_file}" >&2
  exit 1
fi

if [[ ! -f "${wings_file}" ]]; then
  printf 'Panel config not found: %s\n' "${wings_file}" >&2
  exit 1
fi

instance="$(printf '%s' "${plugin_file}" | sed -E 's/^[0-9]+-//; s/\.[0-9]+[smhd]\.sh$//; s/\.sh$//')"

CBAR_SKIP_PANEL_HINT=1 "${script_dir}/install-instance.sh" "${instance}" "${plugin_file}"

python3 - "${wings_file}" "io.github.alexprates.CBar.${instance}" "${side}" <<'PY'
import os
import re
import sys

path, applet_id, side = sys.argv[1:4]
text = open(path, encoding="utf-8").read()

entries = r'(?:\s*"[^"]*"\s*,?)*\s*'
match = re.fullmatch(rf'\s*Some\(\(\s*\[({entries})\]\s*,\s*\[({entries})\]\s*,?\s*\)\)\s*', text)
if match is None:
    sys.exit(f"unexpected panel config format, left unchanged: {path}")

start, end = (re.findall(r'"([^"]*)"', group) for group in match.groups())
if applet_id in start or applet_id in end:
    print(f"Already in panel: {applet_id}")
    sys.exit(0)

(start if side == "start" else end).append(applet_id)


def render(items):
    if not items:
        return "[]"
    return "[\n" + "".join(f'    "{item}",\n' for item in items) + "]"


tmp_path = path + ".tmp"
with open(tmp_path, "w", encoding="utf-8") as f:
    f.write(f"Some(({render(start)}, {render(end)}))")
os.replace(tmp_path, path)
print(f"Added to panel ({side}): {applet_id}")
PY
