---
name: mcp-dockerize
description: Contenedorizar un servidor MCP `command`/stdio de este repo (o de otro repo de Estudio Oro) siguiendo el patrón validado en .claude/docker/memory-mcp.Dockerfile. ACTIVAR cuando el usuario pida "dockerizar" o "contenedorizar" un MCP, cuando un MCP `command` tenga bugs de rutas relativas/hardcodeadas (como los de MEMORY_FILE_PATH en CLAUDE.md), o cuando se quiera aplicar las recomendaciones de informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md a un servidor MCP nuevo.
---

# Dockerizar un servidor MCP `command`/stdio

Playbook extraído de contenedorizar el servidor de memoria de este repo (PRs #12 y #13). Sigue este orden — cada paso existe porque un paso anterior, hecho a mano, produjo un bug real y verificado en este mismo repo. Incluye un caso real de "el fix de un bug rompió otra cosa" (bug #2 abajo): la primera solución quedó mal y hubo que revisarla en una segunda ronda — no asumas que el primer fix que se te ocurra es el final, probalo adversarialmente antes de darlo por bueno.

## Cuándo usar esto

- Un MCP `command` en `.mcp.json` depende de rutas relativas o `npx -y <paquete>` sin pinnear versión.
- Se quiere aislar un MCP con acceso a datos sensibles (credenciales, causas judiciales, datos fiscales) del resto del host.
- El usuario pide explícitamente containerizar/dockerizar un servidor MCP.

**No usar** para MCPs que ya corren como servicios remotos (HTTP/SSE) — esto es específico de servidores `command`/stdio locales.

## Los 4 bugs que este playbook evita (ya ocurrieron acá, no repetir)

1. **Ruta hardcodeada rota** (CLAUDE.md, bugs #1 y #2 de `MEMORY_FILE_PATH`): nunca hardcodear una ruta absoluta en `.mcp.json` o el Dockerfile — el harness puede remontar el repo en otra carpeta entre sesiones.
2. **Ownership de un bind mount — dos fixes, el primero rompió otra cosa** (hallazgo real de `cubic`, PR #12 y luego PR #13):
   - *Intento 1 (mal):* `RUN chown -R user:user /data` en el Dockerfile no sirve contra un bind mount — la ownership del host gana y el proceso sin privilegios se encuentra con `EACCES`.
   - *Intento 2 (también mal, más sutil):* "arreglarlo" con un `entrypoint.sh` que arranca como root, hace `chown -R user:user /data` en cada arranque, y baja privilegios con `su-exec`. Esto funciona para el contenedor pero **muta permanentemente la ownership real del directorio del host** la primera vez que corre — si algo más (un script sin Docker, otro usuario del sistema) espera que ese directorio siga siendo del usuario original, se rompe con `EACCES` desde el lado del host.
   - **Fix correcto:** no tocar la ownership del bind mount nunca. La imagen no fija un usuario propio; quien invoca el contenedor pasa `docker run --user "$(id -u):$(id -g)"`, así el proceso adentro corre con exactamente los mismos permisos que el usuario del host. Sin chown, sin mutación, sin necesidad de arrancar como root ni de su-exec/gosu. El wrapper script (paso 6) es quien agrega el `--user` automáticamente.
3. **`COPY` con ruta relativa a la ubicación del Dockerfile en vez de al build context** (hallazgo real de `cubic` en PR #12): `docker build -f subdir/Dockerfile .` resuelve `COPY` contra `.` (el build context, normalmente la raíz del repo), no contra `subdir/`. Un `COPY archivo.sh ...` sin el prefijo de carpeta compila solo si por casualidad el archivo también está en la raíz — probarlo desde una carpeta con la misma estructura que el build real, no copiando todo a un mismo directorio plano (ese atajo enmascaró el bug la primera vez). Si el Dockerfile terminó sin necesitar copiar ningún script propio (como pasó acá tras el fix del punto 2), este bug directamente deja de aplicar — una interfaz más simple también elimina clases enteras de bug.
4. **Volumen anónimo silencioso** (hallazgo real de `cubic` en PR #12): si el `docker run` documentado no lleva `-v host:/container`, Docker crea un volumen anónimo vacío sin avisar — se pierde la persistencia real sin ningún error visible.

## Pasos

1. **Fijar la versión exacta del paquete** que corre el MCP. Verificar contra el registry real (`curl https://registry.npmjs.org/<paquete> | jq '."dist-tags".latest'` o equivalente), nunca asumir un número de versión ni usar `latest`/`npx -y` sin pinnear en la imagen final.
2. **Escribir el Dockerfile** con esta estructura:
   - Imagen base mínima (`node:20-alpine` u equivalente).
   - Instalar el paquete con la versión pinneada del paso 1.
   - Declarar `ENV <VAR_DE_RUTA>=/data/<archivo>` y `VOLUME ["/data"]` — una única ruta de datos, montada, nunca calculada a partir de `$PWD` o similar dentro del contenedor.
   - **Sin `USER` fijo y sin entrypoint propio** (ver bug #2 de arriba) — `ENTRYPOINT ["<binario-del-paquete>"]` directo. Quien corre el contenedor decide el UID/GID con `--user` en runtime (paso 6), no la imagen en build time.
   - Si de verdad hace falta un directorio con permisos abiertos como fallback para el caso sin bind mount (volumen anónimo, no recomendado), usar `chmod 1777` como `/tmp` en vez de fijar un dueño — nunca `chown` a un UID fijo de la imagen.
3. **`.dockerignore`** en la raíz del repo: excluir `.git`, PDFs, informes, y cualquier cosa que no haga falta en el build context.
4. **Documentar el `docker run` completo con el `-v` Y el `--user` obligatorios** en un comentario al inicio del Dockerfile — nunca solo `docker run --rm <imagen>` sin el bind mount (bug #4) ni sin `--user` (bug #2). Si hay un wrapper script, que sea él quien arme ambos, no depender de que quien lo corra se acuerde. Advertir explícitamente que correr el wrapper con `sudo` rompe el cálculo de `$(id -u)` (da el UID de `sudo`, no el del usuario real).
5. Si el Dockerfile necesita copiar un archivo propio del repo (script, config), usar siempre la ruta completa desde la raíz del repo en el `COPY` (bug #3), nunca relativa a la carpeta del Dockerfile.
6. **Wrapper script** (`.claude/bin/run-<nombre>-mcp-docker.sh` o similar) que:
   - Auto-resuelve la ruta del repo con `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"` (mismo patrón que `run-memory-mcp.sh`) — nunca asumir `$PWD`.
   - Rebuildea la imagen solo si el Dockerfile cambió: hashear el archivo (`sha256sum`), comparar contra un stamp cacheado (gitignoreado), rebuildear solo si difiere.
   - Termina con `exec docker run -i --rm --user "$(id -u):$(id -g)" -v "$MEMORY_DIR:/data" "$IMAGE_TAG"` — `-i` sin `-t` (MCP habla por stdio, no es una TTY), `--user` es lo que evita el bug #2.

## Cómo probarlo (obligatorio antes de decir que está "hecho")

El sandbox de Claude Code normalmente no tiene `dockerd` corriendo. Si hace falta:

```
dockerd > /tmp/dockerd.log 2>&1 &
sleep 2 && docker info >/dev/null 2>&1 && echo ok
```

(puede necesitar `dangerouslyDisableSandbox: true` en el Bash tool).

Si el proxy TLS del sandbox rompe `apk`/`npm` durante el build (`SELF_SIGNED_CERT_IN_CHAIN` o similar): es un artefacto del sandbox, no del Dockerfile — para validar la lógica igual, copiar el Dockerfile a un directorio temporal, inyectar el CA bundle del proxy (`/root/.ccr/ca-bundle.crt`) y cambiar `https` por `http` en los repos de paquetes del gestor de la imagen base **solo en esa copia de prueba**, nunca en el archivo que se commitea.

Checklist de smoke test, en este orden:

1. **Build exacto documentado**: reproducir el comando de build tal cual está escrito en el Dockerfile/README, desde una copia limpia del repo (sin cache de un build anterior que pueda estar enmascarando un bug de rutas — ver bug #3).
2. **Bind mount con ownership adversarial, en los dos sentidos**: no alcanza con confirmar que el contenedor puede escribir — hay que confirmar también que **no mutó nada del lado del host**. Crear un usuario/UID de prueba distinto tanto de root como del UID que tenía la imagen antes del fix (ej. `useradd -u 2500 -M testuser`), poner un directorio de prueba a su nombre, correr el contenedor con `--user 2500:2500` contra ese directorio, y comparar `stat -c '%u:%g' <dir>` **antes y después** — tienen que ser idénticos. Esto es lo que hubiera atrapado tanto el bug #2 original (`EACCES`) como su primer "fix" (mutación silenciosa de ownership) antes de mergear cualquiera de los dos.
3. **Handshake MCP real**: mandar un `initialize` JSON-RPC por stdin y confirmar la respuesta (`serverInfo`, `capabilities`).
4. **Al menos una operación de lectura y una de escritura reales** contra el volumen montado (no solo el handshake) — confirmar que el archivo de datos real se actualiza. Si la imagen no fija un usuario propio (patrón recomendado, ver bug #2), confirmar en cambio que `--user` efectivamente se está pasando y que coincide con quien corre el script (`docker run --user "$(id -u):$(id -g)" --entrypoint id <imagen>` para verificarlo).
5. **Si se va a tocar el archivo de datos real del repo** (no una copia): hacer backup antes (`cp archivo /tmp/backup`), probar solo con operaciones de lectura contra el archivo real, y hacer `diff` después para confirmar que no cambió. Las escrituras de prueba van siempre contra una copia en `/tmp`, nunca contra el archivo de producción versionado en git.
6. **Rama de rebuild**: forzar un cambio de hash (por ejemplo, agregar un comentario al Dockerfile) y confirmar que el wrapper *intenta* un rebuild — no hace falta que el build termine con éxito si el sandbox no tiene red, alcanza con confirmar que la detección de cambio disparó el intento.

## Qué documentar al terminar

- Actualizar `CLAUDE.md` con una entrada fechada explicando qué se dockerizó y por qué (siguiendo el estilo de las entradas de `MEMORY_FILE_PATH` ya existentes).
- Si existe un informe relacionado (como `informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md`), marcar el punto correspondiente como hecho con la fecha y qué se validó.
- Nunca cambiar el `.mcp.json` que usa el harness remoto por defecto a una versión que dependa de Docker, salvo que se haya confirmado que ese entorno remoto garantiza un daemon de Docker disponible — documentar el cambio de config como opt-in manual para quien corra el repo en una máquina con Docker persistente (local/WSL), no como default.
