# Informe: "The State of Agentic AI" (Docker, 2026) aplicado al ecosistema NARAKIA / Estudio Oro

**Fecha:** 2026-09-11
**Fuente primaria:** Docker — *The State of Agentic AI Report* (encuesta a 805 practitioners técnicos, IT decision-makers, Q2026). [VERIFICAR] cifras exactas contra el PDF original si se cita en un documento externo — este informe resume y reinterpreta, no reemplaza la fuente.

## 1. Por qué este informe existe

Doctor pidió leer el white paper de Docker sobre el estado de la IA agéntica y "crear, agregar, usar y mejorar" el repo con eso. Este repo (`pagina-oro-loader`) es hoy la base de infraestructura de memoria persistente (MCP) y auditoría de costos para todo el ecosistema Estudio Oro / NARAKIA. El white paper es, en esencia, un mapa de los mismos problemas que ya venimos parcheando acá (bugs de `MEMORY_FILE_PATH`, rutas hardcodeadas, falta de sandboxing) — así que este informe traduce sus hallazgos a acciones concretas para NARAKIA, los bots de WhatsApp (Lucrecia, Natalia, Megan, Paula), el memory-engine y el resto de los 6 negocios.

## 2. Hallazgos clave del reporte (resumen ejecutivo)

- **Adopción rápida, madurez temprana:** 60% de las organizaciones ya tienen agentes en producción; 94% lo considera prioridad estratégica. Pero casi todo el uso es interno (productividad, DevOps), no todavía cara al cliente/revenue.
- **Seguridad es la barrera #1:** 40% cita seguridad/compliance como el principal obstáculo para escalar; 45% no logra garantizar que sus herramientas de IA agéntica sean seguras y "enterprise-ready".
- **Complejidad de orquestación:** 33% reporta dificultades de orquestación; 79% corre agentes en 2+ entornos (multi-cloud/multi-modelo). El 48% dice que coordinar múltiples componentes es su desafío #1.
- **MCP (Model Context Protocol) — la pieza que más nos toca:** 85% lo conoce, 2/3 lo usa activamente, pero:
  - 42% reporta sobrecarga operativa manejando servers/clients MCP.
  - 41% tiene problemas de instalación/configuración.
  - 41% tiene dudas de seguridad/compliance.
  - 46% teme vulnerabilidades específicas: **prompt injection indirecto, tool poisoning, rug pulls**.
  - 44% no logra encontrar servers MCP confiables.
  - Conclusión del reporte: MCP funciona "en modo salto de fe" — se adopta sin las garantías de seguridad que se exigirían a infraestructura madura.
- **Contenedores son la base, no una opción:** 94% ya usa contenedores para desarrollo/producción de agentes; 98% usa los mismos workflows cloud-native que para software tradicional.
- **Distribución/sharing de agentes es lo menos maduro:** no hay estándar de empaquetado (algo así como "OCI para agentes" todavía no existe). 66% usa marketplaces, 51% repos Git, 48% wikis/documentación interna informal — versión artesanal, frágil, difícil de auditar.
- **Miedo al vendor lock-in:** 76% global (88% Francia, 83% Japón, 82% UK) le preocupa quedar atado a un proveedor de modelos/nube. La respuesta de la industria es diversificar (multi-modelo, multi-cloud) en vez de consolidar.

## 3. Traducción directa a nuestros problemas ya documentados en este repo

Este CLAUDE.md ya tiene tres "bugs confirmados" sobre el servidor MCP de memoria (`MEMORY_FILE_PATH` no se expandía, ruta hardcodeada rota, y ahora resuelta en runtime vía `run-memory-mcp.sh`). Eso es, textualmente, el síntoma que el reporte describe en la sección de MCP:

| Hallazgo del reporte | Cómo se manifestó acá |
|---|---|
| 41% tiene problemas de instalación/configuración de MCP | Los 3 bugs consecutivos de `MEMORY_FILE_PATH` (`${CLAUDE_PROJECT_DIR}` sin expandir → ruta hardcodeada rota → wrapper con `BASH_SOURCE`) |
| 42% reporta sobrecarga operativa manejando servers MCP | Cada vez que el harness monta el repo en una carpeta distinta, hay que re-verificar la ruta a mano |
| 36% no logra aislar servers MCP del host | El server de memoria corre como proceso `stdio` local sin sandboxing — funciona porque el entorno es de confianza, pero no escala a un MCP de terceros |
| 44% no encuentra servers MCP confiables | Los MCPs de terceros conectados a esta sesión (53 conexiones de terceros confirmadas — 52 vía `ListConnectors` + GitHub, ver `informes/2026-09-12-auditoria-conectores-mcp.md`: Supabase, Make, GitHub, etc.) no tienen proceso de verificación propio más allá de "está en la lista de conectores de Anthropic" |

## 4. Recomendaciones concretas para Estudio Oro / NARAKIA

### 4.1 Memoria persistente y MCP propios (prioridad alta)
1. **Contenerizar el wrapper de memoria.** Hoy `run-memory-mcp.sh` resuelve su ruta vía `BASH_SOURCE` porque el harness reubica el repo. Empaquetarlo en una imagen Docker con la ruta fija adentro (`/data/knowledge-graph.jsonl` como volumen montado) elimina esa clase entera de bug — es exactamente el patrón "containers como sustrato" que el 94% de las orgs ya usa.
2. **Sandboxing explícito — auditado (2026-09-12).** Este repo (`.mcp.json`) solo define un MCP propio, `memory`, ya contenedorizable (punto 1). El resto de las 53 conexiones de terceros visibles en esta sesión (Supabase, Make, Neon, Base44, GitHub, etc. — inventario completo en `informes/2026-09-12-auditoria-conectores-mcp.md`) **no son configuración de este repo** — se gestionan a nivel de cuenta de Claude.ai (conectores), así que no hay nada que "sandboxear" desde archivos acá; el control real está en qué conectores tiene habilitados la cuenta, no en este repo. Hallazgo concreto que sí vale la pena que el Doctor sepa: los 4 bots NARAKIA (`s5542584_lucrecia_gemini_bot` y hermanos, ver `bots/manifest-narakia.md`) están expuestos como MCP tools con la descripción explícita *"calling this tool EXECUTES the Make scenario immediately (side-effecting; consumes operations)"* — cualquier sesión de Claude con el conector de Make activo puede disparar un mensaje real de WhatsApp-Gemini a un cliente sin pedir confirmación extra, más allá del permiso general de usar la herramienta. No es un bug, es el diseño de Make MCP, pero es el tipo de "credenciales compartidas entre sesión interactiva y producción" que el punto 2 original de este ítem señalaba — vale la pena decidir conscientemente si eso debe seguir así o si conviene un conector separado solo-lectura para sesiones de auditoría.
3. **Versionar y firmar el knowledge-graph.jsonl** antes de cada commit relevante (ya se hace vía git, que cumple parcialmente el rol de "provenance tracking" que el reporte pide para agentes — pero falta un `CHANGELOG` corto por entidad crítica: causa CCC 28.979/2020, datos fiscales, credenciales de infraestructura).

### 4.2 Bots NARAKIA (Lucrecia, Natalia, Megan, Paula — Gemini bots en Make)
1. Estos bots ya corren como escenarios de Make, no como contenedores propios — el reporte marca esto como el patrón "pre-container microservices era": configuración manual, versionado a mano, comportamiento en runtime impredecible. Riesgo real: un bot desconfigurado (mencionado explícitamente en `boris-super-bots` skill) es el mismo síntoma que "orchestration sprawl" del reporte.
2. **HECHO (2026-09-12):** `bots/manifest-narakia.md` — manifiesto versionado con datos verificados directamente contra la API de Make (`scenarios_get`) para los 4 bots: scenario ID, modelo, prompt de sistema completo, fecha de última edición, estado activo. Incluye una sección de riesgos detectados en el blueprint real (sin sandboxing de input, link de pago hardcodeado en el prompt de Paula, reglas de marca duplicadas en los 4 prompts en vez de una fuente única).
3. Evaluar si conviene mover la lógica más crítica (validación de prompts, memoria de conversación) fuera de Make y a un contenedor propio con Supabase como backend — control total, sin lock-in al motor visual de Make. Esto responde directamente al 76% de organizaciones que temen vendor lock-in.

### 4.3 Gobierno y checklist de seguridad (aplica a todo el ecosistema)
Basado en la sección "Next steps for leading companies" del reporte, checklist mínimo para Estudio Oro — revisado el 2026-09-12 con evidencia real, no solo intención:

- [x] **Usar solo fuentes verificadas para modelos y MCP servers.** El único MCP propio de este repo (`memory`) ya pinnea versión exacta del paquete npm (verificado contra el registry, ver `.claude/docker/memory-mcp.Dockerfile`). Los bots NARAKIA usan `gemini-2.5-flash` (nombre de modelo fijo en el blueprint de Make, no `latest`). Parcial: las 53 conexiones de terceros de esta cuenta de Claude.ai no están bajo control de versión de este repo — eso depende de la plataforma, no de algo que este repo pueda fijar.
- [ ] **Tratar sandboxing y manejo de credenciales como arquitectura, no como checklist post-hoc.** Parcialmente cumplido para `memory` (usuario no-root, ownership corregida en runtime — PR #12). Sin cumplir para los bots de Make: corren con las credenciales de producción de la cuenta de Make, sin un usuario/token separado de menor privilegio para uso desde sesiones de Claude (ver hallazgo en 4.1.2 de arriba).
- [x] **Diversificar sin dispersar.** Supabase + Make + Netlify + React 18.3.1 CDN sigue siendo la arquitectura deliberada; este repo + `bots/manifest-narakia.md` + `informes/` ya centralizan el registro documental de esa diversidad en vez de dejarlo disperso en la cabeza de una sola persona.
- [ ] **Empaquetado portable.** El Dockerfile de memoria (PR #12/#13) es el primer caso real, pero los bots NARAKIA siguen 100% en Make — ningún bot se migró a contenedor todavía. Sigue pendiente si/cuando se decida sacar alguno de Make.
- [ ] **Orquestación estándar / gateway único — sigue sin implementar; auditoría completada el 2026-09-12.** No hay gateway ni registro central. Lo que sí se hizo es la auditoría inicial: **53 conexiones de terceros** activas simultáneamente (52 vía `ListConnectors` + GitHub, recontado explícitamente tras un error real de conteo — no la estimación de "~40"/"30+" que se usaba antes en este informe) — el escenario "orchestration sprawl" del reporte de Docker (problema #1, 48% de las orgs) confirmado con datos reales, no solo en teoría. Ver `informes/2026-09-12-auditoria-conectores-mcp.md` para el detalle: 5 hallazgos concretos, entre ellos Supabase (producción) y Neon (branches de preview por PR, uso real documentado en `informes/2026-08-22-auditoria-costos-infraestructura.md`) coexistiendo con funciones distintas — pendiente confirmar si ese workflow de Neon sigue vigente, no una redundancia a resolver sin más; 10 plataformas de hosting cuando la arquitectura real es Netlify+Supabase+Make; 5 canales de email simultáneos, uno roto; 5 herramientas de ads/SEO solapadas; 4 conectores sin conexión aparente al negocio. El punto sigue sin marcar como hecho a propósito: la auditoría identificó el problema, no lo resolvió — las bajas de conectores quedan pendientes de que el Doctor las confirme.

## 5. Qué NO hacer (según el reporte, aplicado a nuestro caso)

- No asumir que porque MCP "funciona" en desarrollo está listo para producción con datos sensibles (causa penal, datos fiscales, CUIT). El propio reporte dice que la mayoría opera en "modo salto de fe".
- No multiplicar MCPs/bots sin un registro central — es la causa directa de la "orchestration sprawl" que el 48% de las orgs cita como problema #1.
- No tratar la corrección de bugs de infraestructura (como los 3 fixes de `MEMORY_FILE_PATH` ya documentados) como hechos aislados — son síntoma de un patrón de industria conocido, y la solución de fondo (contenerizar) ya está identificada arriba.

## 6. Próximo paso sugerido — HECHO (2026-09-12, corregido tras review de `cubic`)

Se agregó `.claude/docker/memory-mcp.Dockerfile`: imagen que fija la versión del paquete npm `@modelcontextprotocol/server-memory` (2026.8.31, verificada contra el registry de npm) y corre el server MCP como usuario no-root (`node`) — elimina de raíz la clase de bug de rutas relativas que motivó los 3 fixes de `MEMORY_FILE_PATH` documentados en `CLAUDE.md`.

**Cómo usarla — el bind mount NO es opcional:**

```
docker build -f .claude/docker/memory-mcp.Dockerfile -t oro-memory-mcp .
docker run -i --rm -v "$(pwd)/.claude/memory:/data" oro-memory-mcp
```

Si se corre `docker run` **sin** el `-v "$(pwd)/.claude/memory:/data"`, Docker crea un volumen anónimo vacío: el `knowledge-graph.jsonl` real de este repo no se carga, y todo lo que el agente escriba durante esa sesión se pierde al borrar el contenedor — exactamente el mismo tipo de pérdida silenciosa de memoria que el Bug #2 de `MEMORY_FILE_PATH` ya causó una vez. `$(pwd)` asume que el comando se corre desde la raíz del repo.

**Corrección de ownership — 2 rondas de hallazgos reales de `cubic`:**

- *Ronda 1 (PR #12):* la primera versión de este Dockerfile hacía `chown -R node:node /data` solo en build time, lo cual no sirve de nada contra un bind mount — la ownership del directorio del host pisa lo que la imagen haya hecho, y el proceso `node` se hubiera encontrado con `EACCES` al intentar escribir. Se "corrigió" agregando `.claude/docker/entrypoint.sh`: el contenedor arrancaba como root, corregía el dueño de `/data` en cada arranque, y recién ahí bajaba privilegios a `node` vía `su-exec`.
- *Ronda 2 (PR #13) — ese fix rompía otra cosa:* `cubic` marcó que ese `chown -R` en cada arranque **muta permanentemente** la ownership real de `.claude/memory/` en el filesystem del host al UID fijo de la imagen (1000). Si el usuario del host no es UID 1000, `run-memory-mcp.sh` (el wrapper sin Docker, que corre con el UID real del usuario) deja de poder escribir `knowledge-graph.jsonl` la primera vez que se usa sin Docker después de haber usado la versión Docker — el fix de la ronda 1 solucionaba el contenedor rompiendo el host.
- **Fix definitivo (2026-09-12):** se eliminó `entrypoint.sh` y todo el mecanismo de chown/root/su-exec. En su lugar, el contenedor no fija ningún usuario propio — quien lo corre pasa `docker run --user "$(id -u):$(id -g)"` (lo hace `run-memory-mcp-docker.sh` automáticamente), así el proceso dentro del contenedor tiene exactamente los mismos permisos que el usuario del host, sin tocar la ownership de nada. Validado simulando un usuario de host arbitrario (UID 2500, ni root ni el 1000 original): lectura y escritura funcionan sin `EACCES`, y la ownership del directorio del host queda exactamente igual antes y después de correr el contenedor (`stat` confirmó `2500:2500` sin cambios).

Validado localmente con `dockerd` + `docker build` + un handshake MCP real (`initialize` por stdin) — respondió correctamente, el server corrió como `uid=1000(node)`, y se confirmó que el bind mount con un directorio de host propiedad de `root` se corrige solo al arrancar.

**Integración con `.mcp.json` para local/WSL — HECHO (2026-09-12):** se agregó `.claude/bin/run-memory-mcp-docker.sh`, el equivalente Docker de `run-memory-mcp.sh` (mismo patrón de auto-resolución de ruta vía `BASH_SOURCE`). Rebuildea la imagen solo cuando el Dockerfile cambia (hash cacheado, sin rebuilds innecesarios en cada arranque) y monta el `.claude/memory/` real del repo pasando `--user "$(id -u):$(id -g)"` (ver "Corrección de ownership" más abajo). Se probó de punta a punta simulando exactamente cómo lo invocaría `.mcp.json` (`bash .claude/bin/run-memory-mcp-docker.sh` desde la raíz del repo, handshake `initialize` + `read_graph` por stdin): cargó correctamente una entidad real del `knowledge-graph.jsonl` de producción de este repo (la de arquitectura de memoria WSL) sin modificarlo, y se confirmó por separado (forzando un cambio de hash) que la detección de "necesita rebuild" dispara un build real cuando corresponde.

Queda **sin resolver** — y así se deja adrede — si el harness de Claude Code on the web garantiza un daemon de Docker disponible al arrancar una sesión remota; por eso `.mcp.json` en este repo sigue apuntando a `run-memory-mcp.sh` (sin Docker) por defecto. Para usar la versión Docker en una máquina local/WSL con Docker corriendo, hay que cambiar manualmente en `.mcp.json` el `args` de la entry `"memory"` de `.claude/bin/run-memory-mcp.sh` a `.claude/bin/run-memory-mcp-docker.sh` — cambio de una línea, documentado en `CLAUDE.md`, no aplicado por defecto porque rompería sesiones remotas sin Docker.

---
*Fuente: Docker, "The State of Agentic AI Report" (PDF adjuntado por el usuario, ~313KB, 27 páginas). Metodología: 805 encuestados, panel global online, IT decision-makers/DevOps/App Devs, Q1-Q2 2026 (ver Apéndice del reporte original para el detalle completo de metodología).*
