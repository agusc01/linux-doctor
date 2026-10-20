# linux-doctor

Diagnóstico **de solo lectura** para Alpine Linux, Debian y Ubuntu, utilizable desde TTY sin Fish ni Xorg. No requiere root.

## Instalación

```sh
git clone https://github.com/agusc01/linux-doctor.git
cd linux-doctor
sh install.sh --dry-run
sh install.sh
```

Se instala en `~/.local/bin/linux-doctor` y `~/.local/share/linux-doctor` sin sudo ni doas. No sobrescribe lanzadores preexistentes. Para usar el comando, `~/.local/bin` debe estar en el PATH. Alternativamente ejecutá `sh doctor.sh` desde el clon.

## Actualización explícita y segura

La instalación normal **no sobrescribe nada**. Para actualizar una instalación anterior que pertenezca a linux-doctor, descargá la revisión nueva y ejecutá:

```sh
sh install.sh --update
```

Si lo instalaste desde [linux-setup](https://github.com/agusc01/linux-setup), la actualización puede realizarse con `sh install.sh --modules doctor --update` desde ese repositorio, una vez integrado el módulo de actualización.

`--update` verifica que el lanzador sea el propio de linux-doctor y que los archivos existentes no sean enlaces simbólicos. Copia el directorio existente a un área temporal, conserva archivos adicionales (como preferencias), valida la sintaxis del código nuevo y lo sustituye después de guardar la versión anterior bajo `~/.local/state/linux-doctor/backups/`. Si falla el reemplazo intenta restaurar automáticamente la versión previa. No necesita `sudo` o `doas`, no actualiza otros módulos y no ejecuta las reparaciones de `linux-doctor --repair`.

**Importante:** la operación utiliza los archivos de la copia fuente desde la que ejecutás `install.sh`: obtené previamente una revisión actualizada o usá el comando de `linux-setup`, que descarga una copia temporal nueva. El respaldo queda disponible para recuperación manual. La comprobación de archivos administrados impide sobrescribir instalaciones que no reconozca.

## Opciones

```sh
linux-doctor
linux-doctor --verbose
linux-doctor --json
linux-doctor --repair
linux-doctor --version
linux-doctor --help
```

`OK`: verificado. `WARN`: atención recomendada. `FAIL`: problema significativo. `SKIP`: componente opcional no instalado. Código de salida 0 sin FAIL, 1 si hay FAIL y 2 para argumentos inválidos.

**En la versión 0.1 `--repair` solo sugiere reparaciones**, no ejecuta cambios. El diagnóstico no modifica el sistema, no eleva privilegios, no reinicia servicios ni intenta conectarse a internet. La presencia de herramientas no garantiza su funcionamiento; no confundir presencia de DNS con conectividad real. El diagnóstico de fuentes detecta también el fallo conocido del fork de dwm cuando solicita Ubuntu y no está instalada.

## Servicios (OpenRC y systemd)

Además de comprobar si existen los comandos, `linux-doctor` consulta **sin cambios** el estado de servicios mediante `rc-service <servicio> status` en Alpine y `systemctl is-active <servicio>.service` en Debian/Ubuntu.

- Bluetooth: consulta `bluetooth` cuando existe `bluetoothctl`.
- Red: consulta `NetworkManager` si existe `nmcli`, o `wpa_supplicant` si existe `wpa_cli`.
- `OK`: servicio activo. `WARN`: servicio registrado pero detenido o fallido. `SKIP`: sin herramienta, servicio no registrado o estado no verificable.

Estas comprobaciones son **orientativas**: pueden existir gestores alternativos, sesiones sin systemd, un adaptador Bluetooth ausente, o procesos de Wi-Fi ejecutados directamente sin servicio registrado. No se hacen conexiones a Internet ni se ejecutan `start`, `stop`, `enable` o `restart`. Un servicio activo no demuestra que tenga acceso a Internet ni que detecte un dispositivo físico.

## Pruebas

```sh
sh tests/check.sh
sh tests/services.sh
```

Shell POSIX en Alpine y Debian/Ubuntu. Python 3 solo se utiliza en tests para validar JSON; no es una dependencia del programa. Los módulos opcionales ausentes nunca deben marcarse como errores por sí solos.

## Roadmap

- Distinguir módulos solicitados por linux-setup de los módulos opcionales ausentes.
- Comprobaciones funcionales opt-in de Xorg, Wi-Fi, audio y dispositivos.
- Reparación segura con confirmación, respaldo y verificación.
