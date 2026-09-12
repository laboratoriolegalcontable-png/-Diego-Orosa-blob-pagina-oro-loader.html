---
name: mcp-dockerize
description: Contenedorizar un servidor MCP `command`/stdio de este repo (o de otro repo de Estudio Oro) siguiendo el patrón validado en .claude/docker/memory-mcp.Dockerfile. ACTIVAR cuando el usuario pida "dockerizar" o "contenedorizar" un MCP, cuando un MCP `command` tenga bugs de rutas relativas/hardcodeadas (como los de MEMORY_FILE_PATH en CLAUDE.md), o cuando se quiera aplicar las recomendaciones de informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md a un servidor MCP nuevo.
---

# Dockerizar un servidor MCP `command`/stdio

Playbook extraído de contenedorizar el servidor de memoria de este repo (PRs #12 y #13). Sigue este orden — cada paso existe porque un paso anterior, hecho a mano, produjo un bug real y verificado en este mismo repo.

## Cuándo usar esto

- Un MCP `command` en `.mcp.json` depende de rutas relativas o `npx -y <paquete>` sin pinnear versión.
- Se quiere aislar un MCP con acceso a datos sensibles (credenciales, causas judiciales, datos fiscales) del resto del host.
- El usuario pide explícitamente containerizar/dockerizar un servidor MCP.

**No usar** para MCPs que ya corren como servicios remotos (HTTP/SSE) — esto es específico de servidores `command`/stdio locales.

## Los 4 bugs que este playbook evita (ya ocurrieron acá, no repetir)

1. **Ruta hardcodeada rota** (CLAUDE.md, bugs #1 y #2 de `MEMORY_FILE_PATH`): nunca hardcodear una ruta absoluta en `.mcp.json` o el Dockerfile — el harness puede remontar el repo en otra carpeta entre sesiones.
2. **`chown` en build time no sirve contra un bind mount** (hallazgo real de `cubic` en PR #12): un `RUN chown -R user:user /data` en el Dockerfile solo aplica a volúmenes anónimos/nombrados. Con `-v host:/data`, la ownership del host gana y el proceso sin privilegios se encuentra con `EACCES`.
3. **`COPY` con ruta relativa a la ubicación del Dockerfile en vez de al build context** (hallazgo real de `cubic` en PR #12): `docker build -f subdir/Dockerfile .` resuelve `COPY` contra `.` (el build context, normalmente la raíz del repo), no contra `subdir/`. Un `COPY entrypoint.sh ...` sin el prefijo de carpeta compila solo si por casualidad el entrypoint también está en la raíz — probarlo desde una carpeta con la misma estructura que el build real, no copiando todo a un mismo directorio plano (ese atajo enmascaró el bug la primera vez).
4. **Volumen anónimo silencioso** (hallazgo real de `cubic` en PR #12): si el `docker run` documentado no lleva `-v host:/container`, Docker crea un volumen anónimo vacío sin avisar — se pierde la persistencia real sin ningún error visible.

## Pasos

1. **Fijar la versión exacta del paquete** que corre el MCP. Verificar contra el registry real (`curl https://registry.npmjs.org/<paquete> | jq '."dist-tags".latest'` o equivalente), nunca asumir un número de versión ni usar `latest`/`npx -y` sin pinnear en la imagen final.
2. **Escribir el Dockerfile** con esta estructura:
   - Imagen base mínima (`node:20-alpine` u equivalente).
   - Instalar el paquete con la versión pinneada del paso 1.
   - Declarar `ENV <VAR_DE_RUTA>=/data/<archivo>` y `VOLUME ["/data"]` — una única ruta de datos, montada, nunca calculada a partir de `$PWD` o similar dentro del contenedor.
   - `su-exec` (o `gosu`) instalado vía el gestor de paquetes de la imagen base, para poder arrancar como root y bajar privilegios después.
3. **Escribir `entrypoint.sh`** (archivo separado, no inline en el Dockerfile) que:
   - Arranca como root.
   - Hace `chown -R <user>:<user> /data` (o el path de `ENV`) — esto es lo que corrige el bug #2 de arriba, porque corre en cada arranque del contenedor, no en build time.
   - Termina con `exec su-exec <user> <binario-real>` — el proceso que efectivamente habla el protocolo MCP nunca corre como root.
4. **`COPY --chmod=755 <ruta-completa-desde-la-raiz-del-repo>/entrypoint.sh /usr/local/bin/entrypoint.sh`** — con la ruta completa desde donde se ejecuta `docker build`, nunca relativa a la carpeta del Dockerfile (bug #3).
5. **`.dockerignore`** en la raíz del repo: excluir `.git`, PDFs, informes, y cualquier cosa que no haga falta en el build context.
6. **Documentar el `docker run` completo con el `-v` obligatorio** en un comentario al inicio del Dockerfile — nunca solo `docker run --rm <imagen>` sin el bind mount (bug #4). Si hay un wrapper script, que sea él quien arme el `-v`, no depender de que quien lo corra se acuerde.
7. **Wrapper script** (`.claude/bin/run-<nombre>-mcp-docker.sh` o similar) que:
   - Auto-resuelve la ruta del repo con `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"` (mismo patrón que `run-memory-mcp.sh`) — nunca asumir `$PWD`.
   - Rebuildea la imagen solo si el Dockerfile/entrypoint cambiaron: hashear ambos archivos (`sha256sum`), comparar contra un stamp cacheado (gitignoreado), rebuildear solo si difiere.
   - Termina con `exec docker run -i --rm -v "$MEMORY_DIR:/data" "$IMAGE_TAG"` — `-i` sin `-t` (MCP habla por stdio, no es una TTY).

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
2. **Bind mount con ownership adversarial**: montar un directorio de host que sea propiedad de un usuario distinto al del contenedor (`chown root:root` sobre el directorio de prueba) y confirmar que no hay `EACCES` — esto es lo que hubiera atrapado el bug #2 antes de mergear.
3. **Handshake MCP real**: mandar un `initialize` JSON-RPC por stdin y confirmar la respuesta (`serverInfo`, `capabilities`).
4. **Al menos una operación de lectura y una de escritura reales** contra el volumen montado (no solo el handshake) — confirmar que el archivo de datos real se actualiza y que el usuario del proceso sigue siendo el no-root (`docker run --entrypoint id <imagen>`).
5. **Si se va a tocar el archivo de datos real del repo** (no una copia): hacer backup antes (`cp archivo /tmp/backup`), probar solo con operaciones de lectura contra el archivo real, y hacer `diff` después para confirmar que no cambió. Las escrituras de prueba van siempre contra una copia en `/tmp`, nunca contra el archivo de producción versionado en git.
6. **Rama de rebuild**: forzar un cambio de hash (por ejemplo, agregar un comentario al entrypoint) y confirmar que el wrapper *intenta* un rebuild — no hace falta que el build termine con éxito si el sandbox no tiene red, alcanza con confirmar que la detección de cambio disparó el intento.

## Qué documentar al terminar

- Actualizar `CLAUDE.md` con una entrada fechada explicando qué se dockerizó y por qué (siguiendo el estilo de las entradas de `MEMORY_FILE_PATH` ya existentes).
- Si existe un informe relacionado (como `informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md`), marcar el punto correspondiente como hecho con la fecha y qué se validó.
- Nunca cambiar el `.mcp.json` que usa el harness remoto por defecto a una versión que dependa de Docker, salvo que se haya confirmado que ese entorno remoto garantiza un daemon de Docker disponible — documentar el cambio de config como opt-in manual para quien corra el repo en una máquina con Docker persistente (local/WSL), no como default.
