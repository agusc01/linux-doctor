#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target="$HOME/.local/bin/linux-doctor"
if [ "$#" -eq 0 ]; then set -- ''; fi
[ "$#" -eq 1 ] || { echo 'Demasiados argumentos.' >&2; exit 2; }
case "$1" in
    --help) echo 'Uso: sh install.sh [--dry-run]'; exit 0 ;;
    --dry-run) printf 'Instalaría linux-doctor en %s (sin root).\n' "$target"; exit 0 ;;
    '') ;;
    *) echo 'Opción desconocida.' >&2; exit 2 ;;
esac
if [ -e "$target" ] || [ -L "$target" ]; then
    echo "No se sobrescribe $target; ya existe." >&2
    exit 1
fi
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/linux-doctor/lib"
cp "$root/doctor.sh" "$HOME/.local/share/linux-doctor/doctor.sh"
cp "$root/lib/core.sh" "$HOME/.local/share/linux-doctor/lib/core.sh"
cp "$root/lib/services.sh" "$HOME/.local/share/linux-doctor/lib/services.sh"
chmod 755 "$HOME/.local/share/linux-doctor/doctor.sh"
cat > "$target" <<'WRAPPER'
#!/bin/sh
exec "$HOME/.local/share/linux-doctor/doctor.sh" "$@"
WRAPPER
chmod 755 "$target"
printf 'Instalado: %s\n' "$target"
