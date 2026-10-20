#!/bin/sh
# Pruebas aisladas, sin acceder a systemd/OpenRC reales ni cambiar servicios.
set -eu
root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp/bin"
cat > "$tmp/bin/systemctl" <<'MOCK'
#!/bin/sh
[ "$1" = is-active ] || exit 2
printf '%s\n' "$TEST_STATE"
case "$TEST_STATE" in active) exit 0 ;; *) exit 3 ;; esac
MOCK
cat > "$tmp/bin/nmcli" <<'MOCK'
#!/bin/sh
exit 0
MOCK
cat > "$tmp/bin/bluetoothctl" <<'MOCK'
#!/bin/sh
exit 0
MOCK
chmod +x "$tmp/bin/"*
PATH="$tmp/bin:$PATH"
export PATH
. "$root/lib/core.sh"
. "$root/lib/services.sh"
distro=debian
ld_init
trap 'rm -f "$LD_RESULTS"; rm -rf "$tmp"' EXIT HUP INT TERM
TEST_STATE=active
export TEST_STATE
ld_check_services
grep -Fq 'OK' "$LD_RESULTS"
grep -Fq 'servicio-bluetooth' "$LD_RESULTS"
grep -Fq 'servicio-red' "$LD_RESULTS"
: > "$LD_RESULTS"
TEST_STATE=inactive
export TEST_STATE
ld_check_services
grep -Fq 'WARN' "$LD_RESULTS"
grep -Fq 'systemd: NetworkManager (inactive)' "$LD_RESULTS"
: > "$LD_RESULTS"
TEST_STATE=unknown
export TEST_STATE
ld_check_services
grep -Fq 'SKIP' "$LD_RESULTS"
! grep -Fq 'WARN' "$LD_RESULTS"
# Alpine sin servicio registrado: debe omitirse, no fallar.
distro=alpine
: > "$LD_RESULTS"
ld_service_check servicio-prueba linux-doctor-servicio-inexistente-12345
grep -Fq 'SKIP' "$LD_RESULTS"
echo '[OK] Estados active/inactive/unknown y servicio OpenRC ausente.'
