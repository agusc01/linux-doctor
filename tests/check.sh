#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh -n "$root/doctor.sh"
sh -n "$root/lib/core.sh"
sh -n "$root/lib/services.sh"
sh -n "$root/tests/services.sh"
sh "$root/tests/services.sh"
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
test -f "$tmp/home/.local/share/linux-doctor/lib/services.sh"
HOME="$tmp/home" "$tmp/home/.local/bin/linux-doctor" --version | grep -q '0.1.0'
if HOME="$tmp/home" sh "$root/install.sh" >/dev/null 2>&1; then
    echo 'FALLO: sobrescritura no bloqueada' >&2; exit 1
fi
# Actualización explícita: se preservan configuraciones y se guarda el respaldo.
printf '%s\n' 'configuracion personalizada' > "$tmp/home/.local/share/linux-doctor/personal.conf"
HOME="$tmp/home" sh "$root/install.sh" --update
test -f "$tmp/home/.local/share/linux-doctor/personal.conf"
test "$(cat "$tmp/home/.local/share/linux-doctor/personal.conf")" = 'configuracion personalizada'
test -f "$tmp/home/.local/share/linux-doctor/lib/services.sh"
find "$tmp/home/.local/state/linux-doctor/backups" -name personal.conf | grep -q .
HOME="$tmp/home" "$tmp/home/.local/bin/linux-doctor" --version | grep -q '0.1.0'
# No modificar archivos ajenos: una alteración del launcher impide actualizar.
printf '%s\n' '#!/bin/sh' 'exit 42' > "$tmp/home/.local/bin/linux-doctor"
if HOME="$tmp/home" sh "$root/install.sh" --update >/dev/null 2>&1; then
    echo 'FALLO: actualización aceptó un launcher ajeno.' >&2; exit 1
fi
test "$(cat "$tmp/home/.local/share/linux-doctor/personal.conf")" = 'configuracion personalizada'
printf 'ID=debian\n' > "$tmp/os-release"
LINUX_DOCTOR_OS_RELEASE="$tmp/os-release" sh "$root/doctor.sh" --json > "$tmp/result" || [ "$?" -eq 1 ]
python3 - "$tmp/result" <<'PY'
import json, sys
with open(sys.argv[1]) as handle: data = json.load(handle)
assert any(c['id'] == 'distro' and c['status'] == 'OK' for c in data['checks'])
PY
echo 'OK: shell, Alpine/Debian, JSON, opciones e instalación segura.'
