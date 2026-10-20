#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh -n "$root/doctor.sh"
sh -n "$root/lib/core.sh"
sh -n "$root/install.sh"
sh "$root/doctor.sh" --version | grep -q '0.1.0'
sh "$root/doctor.sh" --help | grep -q -- '--json'
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
printf 'ID=alpine\n' > "$tmp/os-release"
LINUX_DOCTOR_OS_RELEASE="$tmp/os-release" sh "$root/doctor.sh" --json > "$tmp/result" || [ "$?" -eq 1 ]
python3 - "$tmp/result" <<'PY'
import json, sys
with open(sys.argv[1]) as handle:
    data = json.load(handle)
assert data['version'] == '0.1.0'
assert sum(data['summary'].values()) == len(data['checks'])
assert any(c['id'] == 'distro' and c['status'] == 'OK' for c in data['checks'])
assert all(c['status'] in {'OK', 'WARN', 'FAIL', 'SKIP'} for c in data['checks'])
PY
if sh "$root/doctor.sh" --invalid >/dev/null 2>&1; then
    echo 'FALLO: opción inválida aceptada' >&2; exit 1
fi
if sh "$root/doctor.sh" --json --repair >/dev/null 2>&1; then
    echo 'FALLO: combinación inválida aceptada' >&2; exit 1
fi
sh "$root/install.sh" --dry-run | grep -q 'sin root'
mkdir -p "$tmp/home"
HOME="$tmp/home" sh "$root/install.sh"
test -x "$tmp/home/.local/bin/linux-doctor"
HOME="$tmp/home" "$tmp/home/.local/bin/linux-doctor" --version | grep -q '0.1.0'
if HOME="$tmp/home" sh "$root/install.sh" >/dev/null 2>&1; then
    echo 'FALLO: sobrescritura no bloqueada' >&2; exit 1
fi
printf 'ID=debian\n' > "$tmp/os-release"
LINUX_DOCTOR_OS_RELEASE="$tmp/os-release" sh "$root/doctor.sh" --json > "$tmp/result" || [ "$?" -eq 1 ]
python3 - "$tmp/result" <<'PY'
import json, sys
with open(sys.argv[1]) as handle: data = json.load(handle)
assert any(c['id'] == 'distro' and c['status'] == 'OK' for c in data['checks'])
PY
echo 'OK: shell, Alpine/Debian, JSON, opciones e instalación segura.'
