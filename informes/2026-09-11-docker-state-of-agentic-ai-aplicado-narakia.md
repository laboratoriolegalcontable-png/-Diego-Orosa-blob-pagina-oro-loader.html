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
| 44% no encuentra servers MCP confiables | Los MCPs de terceros conectados a esta sesión (30+ conectores: Supabase, Make, GitHub, etc.) no tienen proceso de verificación propio más allá de "está en la lista de conectores de Anthropic" |

## 4. Recomendaciones concretas para Estudio Oro / NARAKIA

### 4.1 Memoria persistente y MCP propios (prioridad alta)
1. **Contenerizar el wrapper de memoria.** Hoy `run-memory-mcp.sh` resuelve su ruta vía `BASH_SOURCE` porque el harness reubica el repo. Empaquetarlo en una imagen Docker con la ruta fija adentro (`/app/.claude/memory/knowledge-graph.jsonl` como volumen montado) elimina esa clase entera de bug — es exactamente el patrón "containers como sustrato" que el 94% de las orgs ya usa.
2. **Sandboxing explícito** para cualquier MCP nuevo que Diego conecte (especialmente los que tienen `execute_sql`, `run_command`, o acceso a Supabase/Make en producción — Base44, Neon, Supabase MCP). No correrlos con las mismas credenciales que la sesión interactiva.
3. **Versionar y firmar el knowledge-graph.jsonl** antes de cada commit relevante (ya se hace vía git, que cumple parcialmente el rol de "provenance tracking" que el reporte pide para agentes — pero falta un `CHANGELOG` corto por entidad crítica: causa CCC 28.979/2020, datos fiscales, credenciales de infraestructura).

### 4.2 Bots NARAKIA (Lucrecia, Natalia, Megan, Paula — Gemini bots en Make)
1. Estos bots ya corren como escenarios de Make, no como contenedores propios — el reporte marca esto como el patrón "pre-container microservices era": configuración manual, versionado a mano, comportamiento en runtime impredecible. Riesgo real: un bot desconfigurado (mencionado explícitamente en `boris-super-bots` skill) es el mismo síntoma que "orchestration sprawl" del reporte.
2. Recomendación de bajo costo: documentar cada escenario de Make como si fuera un manifiesto versionado (nombre, modelo, prompt base, fecha de última modificación) en este mismo repo bajo `informes/` o un futuro `bots/manifest.md`, para tener trazabilidad — mitiga el punto de "no hay estándar de empaquetado para agentes".
3. Evaluar si conviene mover la lógica más crítica (validación de prompts, memoria de conversación) fuera de Make y a un contenedor propio con Supabase como backend — control total, sin lock-in al motor visual de Make. Esto responde directamente al 76% de organizaciones que temen vendor lock-in.

### 4.3 Gobierno y checklist de seguridad (aplica a todo el ecosistema)
Basado en la sección "Next steps for leading companies" del reporte, checklist mínimo para Estudio Oro:

- [ ] Usar solo fuentes verificadas para modelos y MCP servers (ya se cumple parcialmente: conectores oficiales de Anthropic/Claude Code).
- [ ] Tratar sandboxing y manejo de credenciales como arquitectura, no como checklist post-hoc.
- [ ] Diversificar sin dispersar: Supabase + Make + Netlify + React 18.3.1 CDN ya es una arquitectura multi-servicio deliberada — mantenerla centralizada en governance (este repo + memory-engine) en vez de dejar que cada bot tenga su propia fuente de verdad.
- [ ] Empaquetado portable: si se migra algún bot fuera de Make, hacerlo directamente como contenedor Docker desde el día uno (no como script suelto).
- [ ] Orquestación estándar: si crece la cantidad de MCP conectados, evaluar un gateway único (el reporte menciona "LLM/MCP gateways" como la herramienta más usada, 43%) en vez de conectar cada servicio suelto.

## 5. Qué NO hacer (según el reporte, aplicado a nuestro caso)

- No asumir que porque MCP "funciona" en desarrollo está listo para producción con datos sensibles (causa penal, datos fiscales, CUIT). El propio reporte dice que la mayoría opera en "modo salto de fe".
- No multiplicar MCPs/bots sin un registro central — es la causa directa de la "orchestration sprawl" que el 48% de las orgs cita como problema #1.
- No tratar la corrección de bugs de infraestructura (como los 3 fixes de `MEMORY_FILE_PATH` ya documentados) como hechos aislados — son síntoma de un patrón de industria conocido, y la solución de fondo (contenerizar) ya está identificada arriba.

## 6. Próximo paso sugerido — HECHO (2026-09-12)

Se agregó `.claude/docker/memory-mcp.Dockerfile`: imagen que fija la versión del paquete npm `@modelcontextprotocol/server-memory` (2026.8.31, verificada contra el registry de npm), corre como usuario no-root (`node`), y monta `/data/knowledge-graph.jsonl` como volumen — elimina de raíz la clase de bug de rutas relativas que motivó los 3 fixes de `MEMORY_FILE_PATH` documentados en `CLAUDE.md`.

Validado localmente con `dockerd` + `docker build` + un handshake MCP real (`initialize` por stdin) — respondió correctamente y el proceso corre con `uid=1000(node)`, no root.

[VERIFICAR CON EQUIPO TÉCNICO] sigue pendiente: si el harness de Claude Code on the web soporta correr MCP servers `command` invocando `docker run` dentro de este entorno remoto (probablemente no — el entorno remoto ya es efímero y aislado por sesión), o si esta imagen aplica solo al entorno local/WSL descrito en `informes/2026-08-22-arquitectura-memoria-distribuida-wsl.md`. Mientras eso no se confirme, `.mcp.json` sigue apuntando a `run-memory-mcp.sh` sin cambios — este Dockerfile es una alternativa disponible, no un reemplazo forzado.

---
*Fuente: Docker, "The State of Agentic AI Report" (PDF adjuntado por el usuario, ~313KB, 27 páginas). Metodología: 805 encuestados, panel global online, IT decision-makers/DevOps/App Devs, Q1-Q2 2026 (ver Apéndice del reporte original para el detalle completo de metodología).*
