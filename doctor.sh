#!/bin/sh
# linux-doctor: no modifica el sistema ni necesita privilegios.
set -eu
BASE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$BASE/lib/core.sh"
json=0
verbose=0
repair=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --json) json=1 ;;
        --verbose|-v) verbose=1 ;;
        --repair) repair=1 ;;
        --version) echo 'linux-doctor 0.1.0'; exit 0 ;;
        --help|-h)
            cat <<'HELP'
Uso: linux-doctor [--verbose] [--json] [--repair] [--version] [--help]
--verbose: muestra comprobaciones omitidas
--json: salida JSON para automatizaciones
--repair: sugiere reparaciones, sin ejecutarlas (v0.1)
El diagnóstico es siempre de solo lectura.
HELP
            exit 0 ;;
        *) echo "Opción desconocida: $1" >&2; exit 2 ;;
    esac
    shift
done
if [ "$json" -eq 1 ] && [ "$repair" -eq 1 ]; then
    echo 'No se puede combinar --json con --repair en v0.1.' >&2
    exit 2
fi
ld_init
ld_run
ld_report "$json" "$verbose" "$repair"
