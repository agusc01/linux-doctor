#!/bin/sh
# Instalador sin root. Actualizaciones explícitas, con backup y rollback.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
app="$HOME/.local/share/linux-doctor"
launcher="$HOME/.local/bin/linux-doctor"
mode=install
[ "$#" -le 1 ] || { echo 'Demasiados argumentos.' >&2; exit 2; }
case "${1-}" in
    --help) echo 'Uso: sh install.sh [--dry-run|--update]'; exit 0 ;;
    --dry-run) mode=dry-run ;;
    --update) mode=update ;;
    '') ;;
    *) echo 'Opción desconocida.' >&2; exit 2 ;;
esac
[ "$(id -u)" -ne 0 ] || { echo 'Ejecutar como usuario normal.' >&2; exit 1; }
for file in doctor.sh lib/core.sh lib/services.sh; do
    [ -f "$root/$file" ] && [ ! -L "$root/$file" ] || {
        echo "Fuente incompleta o enlazada: $file" >&2; exit 1
    }
    sh -n "$root/$file"
done
if [ "$mode" = dry-run ]; then
    echo "Instalación normal: $launcher (sin root; sin reemplazos)."
    echo 'Para actualizar explícitamente: sh install.sh --update'
    exit 0
fi
mkdir -p "$HOME/.local/bin" "$HOME/.local/share" 
wrapper=$(mktemp "$HOME/.local/bin/.linux-doctor-wrapper.XXXXXXXX")
trap 'rm -f "$wrapper"' EXIT HUP INT TERM
cat > "$wrapper" <<'WRAPPER'
#!/bin/sh
exec "$HOME/.local/share/linux-doctor/doctor.sh" "$@"
WRAPPER
if [ "$mode" = install ]; then
    if [ -e "$launcher" ] || [ -L "$launcher" ] || [ -e "$app" ] || [ -L "$app" ]; then
        echo 'Instalación existente: no se sobrescribe. Usá --update para actualizar.' >&2
        exit 1
    fi
else
    if [ ! -f "$launcher" ] || [ -L "$launcher" ] || ! cmp -s "$wrapper" "$launcher"; then
        echo 'El lanzador no pertenece a linux-doctor; no se reemplaza.' >&2; exit 1
    fi
    if [ ! -d "$app" ] || [ -L "$app" ]; then
        echo 'La instalación no es un directorio regular.' >&2; exit 1
    fi
    for file in doctor.sh lib/core.sh lib/services.sh; do
        if [ ! -f "$app/$file" ] || [ -L "$app/$file" ]; then
            echo "Archivo administrado ausente o enlazado: $file" >&2; exit 1
        fi
    done
fi
stage=$(mktemp -d "$HOME/.local/share/.linux-doctor-new.XXXXXXXX")
backup=''
swapped=0
cleanup() {
    code=$?
    if [ "$code" -ne 0 ] && [ "$swapped" -eq 1 ]; then
        if [ -d "$app" ]; then rm -rf "$app"; fi
        mv "$backup/previous" "$app" || echo 'ERROR: restaurá el backup manualmente.' >&2
    fi
    if [ -n "$stage" ] && [ -d "$stage" ]; then rm -rf "$stage"; fi
    rm -f "$wrapper"
}
trap cleanup EXIT
trap 'exit 130' HUP INT TERM
if [ "$mode" = update ]; then
    # Preserva archivos adicionales y preferencias dentro de la instalación.
    cp -R "$app/." "$stage/"
fi
mkdir -p "$stage/lib"
cp "$root/doctor.sh" "$stage/doctor.sh"
cp "$root/lib/core.sh" "$stage/lib/core.sh"
cp "$root/lib/services.sh" "$stage/lib/services.sh"
chmod 755 "$stage/doctor.sh"
sh "$stage/doctor.sh" --version >/dev/null
if [ "$mode" = update ]; then
    mkdir -p "$HOME/.local/state/linux-doctor/backups"
    backup=$(mktemp -d "$HOME/.local/state/linux-doctor/backups/update.XXXXXXXX")
    mv "$app" "$backup/previous"
    swapped=1
fi
mv "$stage" "$app"
stage=''
if [ "$mode" = install ]; then
    chmod 755 "$wrapper"
    # No sobrescribir un launcher creado concurrentemente.
    if [ -e "$launcher" ] || [ -L "$launcher" ]; then
        echo 'El lanzador apareció durante la instalación; no se sobreescribe.' >&2
        exit 1
    fi
    mv "$wrapper" "$launcher"
    echo "Instalado: $launcher"
else
    swapped=0
    echo "Actualización correcta. Backup: $backup/previous"
fi
