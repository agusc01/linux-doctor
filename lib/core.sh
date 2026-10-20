#!/bin/sh
# Checks de solo lectura; nunca escalar permisos ni modificar el sistema.
ld_init() {
    LD_RESULTS=$(mktemp /tmp/linux-doctor.XXXXXXXX) || exit 1
    trap 'rm -f "$LD_RESULTS"' EXIT HUP INT TERM
    LD_OK=0 LD_WARN=0 LD_FAIL=0 LD_SKIP=0
}
ld_has() { command -v "$1" >/dev/null 2>&1; }
ld_add() {
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$LD_RESULTS"
    case "$1" in
        OK) LD_OK=$((LD_OK + 1)) ;;
        WARN) LD_WARN=$((LD_WARN + 1)) ;;
        FAIL) LD_FAIL=$((LD_FAIL + 1)) ;;
        SKIP) LD_SKIP=$((LD_SKIP + 1)) ;;
    esac
}
ld_run() {
    os_file=/etc/os-release
    if [ -n "$LINUX_DOCTOR_OS_RELEASE" ]; then os_file=$LINUX_DOCTOR_OS_RELEASE; fi
    if [ -r "$os_file" ]; then
        distro=$(sed -n 's/^ID=//p' "$os_file" | head -n 1 | tr -d '"')
    else distro=''; fi
    case "$distro" in
        alpine|debian|ubuntu) ld_add OK distro "Distribución compatible: $distro" ;;
        '') ld_add WARN distro 'Distribución no identificada' ;;
        *) ld_add WARN distro 'Distribución no verificada' ;;
    esac
    if [ "$(id -u)" -eq 0 ]; then ld_add WARN usuario 'Ejecutar preferentemente sin root'
    else ld_add OK usuario 'Diagnóstico sin root'; fi
    if ld_has fish; then ld_add OK fish 'Fish disponible'
    else ld_add WARN fish 'Fish no instalado; opcional fuera de linux-setup'; fi
    case ":$PATH:" in
        *:/sbin:*|*:/usr/sbin:*) ld_add OK path-admin 'Rutas administrativas en PATH' ;;
        *) ld_add WARN path-admin 'Faltan /sbin y /usr/sbin del PATH' ;;
    esac
    if ld_has whereis; then ld_add OK whereis 'whereis disponible'
    else ld_add WARN whereis 'Instalar mediante linux-setup'; fi
    if ld_has Xorg || ld_has X; then ld_add OK xorg 'Servidor X disponible'
    else ld_add SKIP xorg 'Xorg no instalado; opcional'; fi
    if ld_has startx; then ld_add OK startx 'startx disponible'
    else ld_add SKIP startx 'startx no instalado'; fi
    if ld_has dwm; then
        ld_add OK dwm 'dwm disponible; inicio no probado'
        if [ -f "$HOME/.xinitrc" ]; then ld_add OK xinitrc 'Existe ~/.xinitrc'
        else ld_add WARN xinitrc 'dwm instalado pero falta ~/.xinitrc'; fi
    else ld_add SKIP dwm 'dwm no instalado; opcional'; fi
    if ld_has st; then ld_add OK st 'st disponible'
    else ld_add SKIP st 'st no instalado; opcional'; fi
    if ld_has dwm || ld_has st; then
        if ! ld_has fc-match; then ld_add FAIL fuentes 'Falta fontconfig'
        elif ! fc-match monospace 2>/dev/null | grep -q .; then
            ld_add FAIL fuentes 'Sin fuente monoespaciada resoluble'
        else ld_add OK fuentes 'Fuente monoespaciada resoluble'; fi
        config=/usr/src/suckless/dwm/config.h
        if [ -n "$LINUX_DOCTOR_DWM_CONFIG" ]; then config=$LINUX_DOCTOR_DWM_CONFIG; fi
        if [ -f "$config" ] && grep -q 'Ubuntu:size=' "$config"; then
            if ld_has fc-list && fc-list : family 2>/dev/null | grep -iE '(^|,|[[:space:]])Ubuntu([,[:space:]]|$)' >/dev/null; then
                ld_add OK fuente-ubuntu 'Fuente Ubuntu disponible'
            else ld_add FAIL fuente-ubuntu 'dwm solicita Ubuntu no instalada'; fi
        else ld_add SKIP fuente-ubuntu 'No se encontró requisito local Ubuntu'; fi
    else
        ld_add SKIP fuentes 'No hay dwm ni st'
        ld_add SKIP fuente-ubuntu 'No hay dwm'
    fi
    if [ -r /etc/resolv.conf ] && grep -q '^[[:space:]]*nameserver[[:space:]]' /etc/resolv.conf; then
        ld_add OK dns 'DNS configurado; conexión no probada'
    else ld_add WARN dns 'No se encontró nameserver'; fi
    if ld_has ip || ld_has ifconfig; then ld_add OK red 'Herramientas de red disponibles'
    else ld_add WARN red 'Faltan ip/ifconfig'; fi
    if ld_has aplay || ld_has wpctl || ld_has pactl; then ld_add OK audio 'Herramientas de audio'
    else ld_add SKIP audio 'Audio no detectado'; fi
    if ld_has iw || ld_has nmcli || ld_has wpa_cli; then ld_add OK wifi 'Herramienta Wi-Fi'
    else ld_add SKIP wifi 'Wi-Fi no detectado'; fi
    if ld_has bluetoothctl; then ld_add OK bluetooth 'bluetoothctl disponible'
    else ld_add SKIP bluetooth 'Bluetooth no detectado'; fi
}
ld_json_escape() {
    printf '%s' "$1" | awk 'BEGIN { ORS="" } { gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, "\\t"); printf "%s", $0 }'
}
ld_report() {
    output_json=$1 output_verbose=$2 output_repair=$3
    if [ "$output_json" -eq 1 ]; then
        printf '{"version":"0.1.0","summary":{"ok":%s,"warnings":%s,"errors":%s,"skipped":%s},"checks":[' "$LD_OK" "$LD_WARN" "$LD_FAIL" "$LD_SKIP"
        first=1
        while IFS="$(printf '\t')" read -r status id detail; do
            if [ "$first" -eq 0 ]; then printf ','; fi
            first=0
            printf '{"status":"%s","id":"%s","message":"%s"}' "$status" "$(ld_json_escape "$id")" "$(ld_json_escape "$detail")"
        done < "$LD_RESULTS"
        printf ']}\n'
    else
        printf 'linux-doctor 0.1.0 | Solo lectura\n\n'
        while IFS="$(printf '\t')" read -r status id detail; do
            if [ "$status" = SKIP ] && [ "$output_verbose" -eq 0 ]; then continue; fi
            printf '[%-4s] %-16s %s\n' "$status" "$id" "$detail"
        done < "$LD_RESULTS"
        printf '\nResumen: %s OK | %s advertencias | %s errores | %s omitidos\n' "$LD_OK" "$LD_WARN" "$LD_FAIL" "$LD_SKIP"
        if [ "$output_repair" -eq 1 ]; then
            echo 'Sugerencias, sin ejecutar reparaciones en v0.1:'
            while IFS="$(printf '\t')" read -r status id detail; do
                case "$status:$id" in
                    FAIL:fuentes|FAIL:fuente-ubuntu) echo '- Reparar dependencias de fuentes desde linux-setup.' ;;
                    WARN:whereis) echo '- Instalar util-linux-misc (Alpine) o util-linux (Debian).' ;;
                    WARN:path-admin) echo '- Revisar fish_add_path /sbin /usr/sbin.' ;;
                esac
            done < "$LD_RESULTS"
        fi
    fi
    [ "$LD_FAIL" -eq 0 ] || return 1
}
