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

## Pruebas

```sh
sh tests/check.sh
```

Shell POSIX en Alpine y Debian/Ubuntu. Python 3 solo se utiliza en tests para validar JSON; no es una dependencia del programa. Los módulos opcionales ausentes nunca deben marcarse como errores por sí solos.

## Roadmap

- Distinguir módulos solicitados por linux-setup de los módulos opcionales ausentes.
- Comprobaciones funcionales opt-in de Xorg, Wi-Fi, audio y dispositivos.
- Reparación segura con confirmación, respaldo y verificación.
