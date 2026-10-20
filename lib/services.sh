#!/bin/sh
# Servicios: comprobaciones de solo lectura, sin iniciar/detener daemons.
# Argumentos: id nombre_de_servicio. Se invoca solo si la herramienta cliente existe.
ld_service_check() {
    service_id=$1
    service_name=$2
    case "$distro" in
        alpine)
            if ! ld_has rc-service; then
                ld_add SKIP "$service_id" 'OpenRC no disponible para comprobar el servicio'
                return
            fi
            # rc-service <nombre> status devuelve 0 para servicio iniciado y
            # código != 0 para detenido/inexistente. Distinguir existencia.
            if [ ! -f "/etc/init.d/$service_name" ]; then
                ld_add SKIP "$service_id" "Servicio $service_name no registrado en OpenRC"
            elif rc-service "$service_name" status >/dev/null 2>&1; then
                ld_add OK "$service_id" "OpenRC: $service_name activo"
            else
                ld_add WARN "$service_id" "OpenRC: $service_name no está activo"
            fi
            ;;
        debian|ubuntu)
            if ! ld_has systemctl; then
                ld_add SKIP "$service_id" 'systemd no disponible'
                return
            fi
            state=$(systemctl is-active "$service_name.service" 2>/dev/null || :)
            case "$state" in
                active) ld_add OK "$service_id" "systemd: $service_name activo" ;;
                inactive|failed|activating|deactivating)
                    ld_add WARN "$service_id" "systemd: $service_name ($state)" ;;
                *)
                    # Unidad inexistente, systemd no operativo o no accesible.
                    ld_add SKIP "$service_id" "No se pudo determinar el estado de $service_name"
                    ;;
            esac
            ;;
        *) ld_add SKIP "$service_id" 'Gestor de servicios no reconocido' ;;
    esac
}
ld_check_services() {
    # bluetoothctl puede estar instalado en un equipo sin adaptador: ausencia
    # del servicio o de la unidad no debe convertirse automáticamente en error.
    if ld_has bluetoothctl; then
        ld_service_check servicio-bluetooth bluetooth
    else
        ld_add SKIP servicio-bluetooth 'Bluetooth no instalado'
    fi

    # Consultar solamente el gestor Wi-Fi cuya herramienta está presente.
    # No asumir que wpa_supplicant y NetworkManager se usan simultáneamente.
    if ld_has nmcli; then
        ld_service_check servicio-red NetworkManager
    elif ld_has wpa_cli; then
        ld_service_check servicio-red wpa_supplicant
    else
        ld_add SKIP servicio-red 'Sin gestor Wi-Fi identificable'
    fi
}
