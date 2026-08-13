# Auditoría Técnica Integral — Repositorio `-Diego-Orosa-blob-pagina-oro-loader.html`

**Fecha de ejecución:** 2026-08-13
**Auditor:** Sesión Claude Code (agente), sobre el repositorio tal como está clonado en este entorno
**Alcance solicitado:** Auditoría hiper-exhaustiva de "el programa" (arquitectura, código, APIs, frontend, backend, BD, auth, sesiones, validaciones, errores, logs, dependencias, secretos, config, infra, CI/CD, performance, concurrencia, resiliencia, backups, monitoreo, privacidad, accesibilidad, compatibilidad, UX, integraciones, operación)

> Convención de etiquetas: `[HECHO]` verificado directamente en este entorno · `[INFERENCIA]` deducción razonable · `[RIESGO]` riesgo identificado · `[PENDIENTE]` requiere acción/insumo externo · `[SUPOSICION]` hipótesis explícita de interpretación del pedido.

---

## 1. Resumen ejecutivo

`[HECHO]` El repositorio auditado, a la fecha de esta sesión, **no contiene una aplicación web, backend, base de datos, API ni frontend funcional**. Su contenido total es: un archivo de configuración MCP (`.mcp.json`), un archivo de instrucciones de proyecto (`CLAUDE.md`), un archivo de memoria vacío (`.claude/memory/knowledge-graph.jsonl`), un workflow de CI de validación liviana (`.github/workflows/memory-mcp-validate.yml`), y dos documentos Markdown de producto/negocio agregados en esta misma sesión (`docs/propuesta-saas-administracion-consorcios.md` y este archivo).

`[HECHO]` No existe ningún `index.html`, ni código de "página oro / loader" pese a que el nombre del repositorio lo sugiere. No hay evidencia de que ese código exista en este repositorio en ningún commit del historial (`git log --all` no lo muestra).

`[HECHO]` Se identificó y verificó **un defecto reproducible y activo**: la ruta hardcodeada en `.mcp.json` (`MEMORY_FILE_PATH=/home/user/pagina-oro-loader/.claude/memory/knowledge-graph.jsonl`) **no existe** en este entorno de ejecución, cuyo working directory real es `/home/user/-Diego-Orosa-blob-pagina-oro-loader.html`. Esto contradice directamente la advertencia que el propio `CLAUDE.md` deja escrita ("verificar que esa ruta coincide con el working directory real antes de confiar en la persistencia") — la verificación nunca se hizo, o se hizo en otro entorno y quedó desactualizada.

`[SUPOSICION]` Se interpreta que el pedido de auditoría busca cobertura sobre "el sistema disponible en este repositorio conectado a la sesión", no sobre un sistema externo (p. ej. el `index.html` local en la PC Windows del usuario, mencionado en un mensaje anterior de esta conversación, al que este entorno no tiene acceso).

**Decisión de cierre (sección 11):** con la información disponible, **no aplica un veredicto de "apto para producción"** porque no existe una aplicación de producción que auditar en este repositorio. Lo que sí se entrega es: (a) auditoría completa de los componentes reales presentes (config MCP + CI), con hallazgos confirmados; y (b) un plan de auditoría exhaustivo y checklist reutilizable para cuando exista código de aplicación real que auditar.

---

## 2. Alcance auditado y alcance pendiente

| Alcance | Estado | Detalle |
|---|---|---|
| Configuración MCP (`.mcp.json`) | `[HECHO]` Auditado | Ver hallazgo H-01 |
| Memoria persistente (`knowledge-graph.jsonl`) | `[HECHO]` Auditado (contenido) | Archivo vacío (0 bytes, 0 líneas) al momento de la auditoría |
| CI/CD (`memory-mcp-validate.yml`) | `[HECHO]` Auditado | Ver hallazgo H-02, H-03 |
| Documentación de proyecto (`CLAUDE.md`) | `[HECHO]` Auditado | Ver hallazgo H-01 |
| Documentos Markdown de negocio (`docs/*.md`) | `[HECHO]` Revisados | No aplica auditoría técnica de "sistema" — son texto, no código ejecutable |
| Frontend / `index.html` / UI | `[PENDIENTE]` **No auditable — no existe en este repo** | Requiere que se suba el código fuente al repositorio, o se conecte el repo/entorno donde realmente vive |
| Backend / APIs | `[PENDIENTE]` **No auditable — no existe** | Ídem |
| Base de datos | `[PENDIENTE]` **No auditable — no existe** | Ídem |
| Autenticación / autorización / sesiones | `[PENDIENTE]` **No auditable — no existe** | Ídem |
| Infraestructura de despliegue (hosting, DNS, CDN) | `[PENDIENTE]` **No auditable** | No hay evidencia de dónde se despliega "pagina-oro-loader.html" |
| Dependencias de aplicación (`package.json`, lockfiles) | `[PENDIENTE]` No existen en el repo | Solo hay dependencia indirecta de `@modelcontextprotocol/server-memory` vía `npx` (no está pineada a versión — ver H-04) |
| Secretos / gestión de credenciales de la app | `[PENDIENTE]` No aplica al repo actual (no hay app); sí se auditó el escáner de secretos del CI (H-03) | |
| Monitoreo / alertas / observabilidad de producción | `[PENDIENTE]` No auditable — no hay servicio en producción vinculado a este repo | |
| Backups / recuperación ante incidentes de la app | `[PENDIENTE]` No auditable | El único "dato" persistente versionado es el knowledge-graph, que vive en git (su backup es el propio historial de git) |
| Accesibilidad / UX / compatibilidad de navegador | `[PENDIENTE]` No auditable — no hay UI | |
| Runtime real del servidor MCP `memory` en esta sesión | `[RIESGO observado, no confirmable con certeza]` | El servidor MCP `memory` apareció como "conectando" y luego se desconectó durante esta misma sesión, sin llegar a exponer sus herramientas de forma estable — ver H-05 |

---

## 3. Inventario de información disponible

| Ítem | Fuente | Estado |
|---|---|---|
| `.mcp.json` | Leído íntegramente | `[HECHO]` |
| `CLAUDE.md` | Leído íntegramente | `[HECHO]` |
| `.github/workflows/memory-mcp-validate.yml` | Leído íntegramente | `[HECHO]` |
| `.claude/memory/knowledge-graph.jsonl` | Leído (vacío) | `[HECHO]` |
| Historial de git completo (4 commits + el de esta sesión) | `git log --all --oneline` | `[HECHO]` |
| Working directory real del entorno | `pwd` | `[HECHO]` → `/home/user/-Diego-Orosa-blob-pagina-oro-loader.html` |
| Runtime de Node/npx disponible | `which npx node && node --version` | `[HECHO]` → Node v22.22.2 disponible |
| Estado de branch protection / reglas del repo en GitHub | No consultado (requiere permisos de administración de repo que no se intentaron ni fueron solicitados) | `[PENDIENTE]` |
| Código fuente de "pagina-oro-loader" / `index.html` real | No presente en este repo ni en ningún commit | `[PENDIENTE]` — solicitar al usuario dónde vive realmente |
| Accesos a ambientes (staging/producción), logs, métricas | No provistos | `[PENDIENTE]` |

---

## 4. Datos que requieren verificación

| # | Dato | Por qué importa | Bloqueo |
|---|---|---|---|
| 1 | Ubicación real del código de la aplicación "pagina-oro-loader" (¿otro repo? ¿solo local en la PC del usuario?) | Sin esto no se puede auditar nada del "programa" en sentido funcional | `[PENDIENTE]` — requiere respuesta del usuario o `add_repo` a un repositorio adicional |
| 2 | Si el `.mcp.json` actual (con ruta hardcodeada rota) está en uso en algún otro entorno donde sí funcione | Determina si H-01 es un problema solo de este entorno o generalizado | `[PENDIENTE]` |
| 3 | Reglas de protección de la rama `main` (revisiones obligatorias, checks requeridos) | Afecta si el CI no-bloqueante (H-02) es mitigado por otra capa de control | `[PENDIENTE]` — requiere acceso admin al repo en GitHub |
| 4 | Si existe un pipeline de despliegue real hacia algún hosting para este proyecto | Sin esto no se puede evaluar infra, backups, monitoreo, recuperación ante incidentes | `[PENDIENTE]` |
| 5 | Versión exacta que resuelve `npx -y @modelcontextprotocol/server-memory` en cada ejecución | Puede variar entre ejecuciones al no estar pineada (H-04) | `[PENDIENTE]` — requiere lockfile o pin de versión explícito |

---

## 5. Mapa de riesgos priorizados

| ID | Área | Riesgo | Severidad | Probabilidad | Impacto | Estado |
|---|---|---|---|---|---|---|
| H-01 | Memoria MCP / persistencia | Ruta hardcodeada en `.mcp.json` no existe en el working directory real de este entorno → el servidor de memoria no puede leer/escribir su archivo (ENOENT) | **Alta** | Alta (confirmado en esta sesión) | Pérdida silenciosa de la funcionalidad de "memoria persistente entre sesiones" que el proyecto dice tener | `[HECHO]` Confirmado |
| H-02 | CI/CD | El workflow de validación (JSON + escaneo de secretos) corre con `continue-on-error: true`, es decir **nunca bloquea un merge** aunque detecte un secreto o un JSON inválido | **Media-Alta** | Media | Un secreto podría mergearse a `main` sin que nada lo impida a nivel de CI | `[HECHO]` Confirmado por lectura del YAML |
| H-03 | Seguridad / escaneo de secretos | El escáner de secretos del CI solo cubre `.claude/memory/knowledge-graph.jsonl`; no escanea el resto del repositorio (código, docs, configs futuras) | Media | Media (crece con el tamaño del repo) | Secretos agregados en cualquier otro archivo no serían detectados | `[HECHO]` Confirmado por lectura del YAML |
| H-04 | Dependencias / supply chain | `.mcp.json` invoca `npx -y @modelcontextprotocol/server-memory` sin pin de versión (`@<versión>`) ni lockfile — cada ejecución puede traer una versión distinta del paquete | Media | Media | Riesgo de comportamiento inconsistente entre sesiones, y de supply-chain (`npx -y` ejecuta código de un paquete de terceros sin confirmación) | `[HECHO]` Confirmado por lectura de `.mcp.json` |
| H-05 | Estabilidad de servidores MCP | El servidor `memory` se observó "conectando" y luego figuró como desconectado durante la misma sesión, sin exponer sus tools de forma estable | Media | `[INFERENCIA]` — no se pudo aislar la causa (¿H-01 es la causa raíz? ¿inestabilidad del harness?) | Funcionalidad de memoria no disponible cuando se la necesita | `[RIESGO]` — causa raíz no confirmada, requiere reproducción controlada |
| H-06 | Alcance del producto | El repositorio no contiene la aplicación que su nombre sugiere (`pagina-oro-loader.html`) | **Crítica para el objetivo de "auditar el programa"**, no para el repo en sí | Alta (confirmado) | Imposibilidad de cumplir el objetivo original de auditoría de "el sistema" sin insumo adicional | `[HECHO]` Confirmado — gap de alcance, no un bug |
| H-07 | Gobernanza de branch protection | No verificado si `main` exige review/checks antes de mergear | `[PENDIENTE]` no evaluable con las herramientas actuales | — | Si no hay protección, cualquier push directo a `main` evita todo control (incluido H-02) | `[PENDIENTE]` |

---

## 6. Checklist maestro de auditoría por dominio

`[SUPOSICION]` Este checklist es el marco completo a aplicar **cuando exista código de aplicación real**. Las filas marcadas `N/A (repo actual)` documentan honestamente que hoy no hay objeto que evaluar, sin inventar resultados.

| Dominio | Ítem de checklist | Estado en este repo |
|---|---|---|
| Requisitos | Especificación funcional documentada y trazable a pruebas | `N/A (repo actual)` — no hay especificación de producto más allá de `docs/propuesta-...md` (propuesta, no requisitos de este repo) |
| Arquitectura | Diagrama de componentes, límites de confianza, flujo de datos | `N/A (repo actual)` |
| Código fuente | Linters, formateo, complejidad ciclomática, cobertura de tests | `N/A (repo actual)` — no hay código de aplicación |
| APIs | Contratos (OpenAPI/GraphQL schema), versionado, rate limiting | `N/A (repo actual)` |
| Frontend | Manejo de estado, XSS, CSP, sanitización de inputs | `N/A (repo actual)` |
| Backend | Validación de entrada, manejo de errores, idempotencia | `N/A (repo actual)` |
| Base de datos | Migraciones, integridad referencial, índices, backups | `N/A (repo actual)` |
| AuthN/AuthZ | Modelo de roles, expiración de sesión, rotación de credenciales | `N/A (repo actual)` |
| Secretos y configuración | Gestión fuera de código, escaneo automático, rotación | Parcial — ver H-02, H-03, H-04 |
| CI/CD | Checks bloqueantes, aprobaciones requeridas, despliegue reproducible | Parcial — ver H-02 |
| Infraestructura | IaC, hardening, gestión de accesos | `N/A (repo actual)` |
| Performance | Carga, estrés, latencia bajo concurrencia | `N/A (repo actual)` |
| Resiliencia | Circuit breakers, reintentos, degradación controlada | `N/A (repo actual)` |
| Backups / DR | RTO/RPO definidos y probados con restauración real | `N/A (repo actual)` — el único dato persistente (knowledge-graph) depende de git como único respaldo, sin prueba de restauración documentada |
| Observabilidad | Logs estructurados, métricas, alertas accionables | `N/A (repo actual)` |
| Privacidad | Clasificación de datos personales, minimización, retención | `N/A (repo actual)` |
| Accesibilidad | WCAG, navegación por teclado, lectores de pantalla | `N/A (repo actual)` |
| Compatibilidad | Matriz de navegadores/dispositivos soportados | `N/A (repo actual)` |
| Integraciones externas | Manejo de fallas de terceros, timeouts, contratos | Parcial — dependencia de `npx` hacia npm registry (ver H-04) |
| Operación | Runbooks, on-call, gestión de incidentes | `N/A (repo actual)` |

---

## 7. Casos de prueba detallados y reproducibles

### Caso T-01 — Verificar resolución de `MEMORY_FILE_PATH`

- **Área/componente:** Servidor MCP `memory`, configuración en `.mcp.json`.
- **Objetivo:** Confirmar si la ruta absoluta configurada existe en el entorno de ejecución real.
- **Procedimiento reproducible:**
  1. En una sesión con este repo clonado, ejecutar `pwd`.
  2. Ejecutar `ls -la /home/user/pagina-oro-loader/.claude/memory/` (la ruta literal de `MEMORY_FILE_PATH`).
- **Resultado esperado (si el sistema fuera correcto):** el directorio existe y el archivo es escribible.
- **Resultado obtenido:** `ls: cannot access '/home/user/pagina-oro-loader/.claude/memory/': No such file or directory` — la ruta **no existe**; el working directory real es `/home/user/-Diego-Orosa-blob-pagina-oro-loader.html`.
- **Evidencia:** salida de comando capturada en esta sesión (ver bloque de comandos ejecutados).
- **Severidad:** Alta.
- **Probabilidad e impacto:** Probabilidad alta de que se repita en cualquier sesión nueva sobre este mismo repo (la causa es estructural, no puntual). Impacto: pérdida de memoria persistente, funcionalidad central documentada en `CLAUDE.md`.
- **Riesgo de negocio/técnico:** Bajo riesgo de negocio directo (es tooling interno), pero alto riesgo de continuidad de contexto entre sesiones de Claude Code — el propósito declarado del sistema de memoria queda incumplido.
- **Recomendación concreta:** Reemplazar la ruta hardcodeada por una relativa al repo si el harness lo soporta, o por una que se derive dinámicamente del working directory real en cada entorno; en su defecto, documentar explícitamente que la ruta debe ajustarse manualmente por entorno antes de cada uso, y agregar una verificación automática (script o step de CI) que falle visiblemente si la ruta no resuelve.
- **Criterio de cierre verificable:** `ls` sobre la ruta configurada en `MEMORY_FILE_PATH` resuelve sin error en el entorno donde se ejecute la sesión, verificado en al menos una sesión nueva post-fix.
- **Estado:** **Validado (hallazgo confirmado, fix pendiente).**

### Caso T-02 — Verificar si el CI bloquea un secreto detectado

- **Área/componente:** `.github/workflows/memory-mcp-validate.yml`.
- **Objetivo:** Confirmar si un secreto agregado al `knowledge-graph.jsonl` impide el merge de un PR.
- **Procedimiento reproducible:**
  1. En una rama de prueba (nunca en `main` sin aprobación), agregar una línea con un patrón que matchee la regex del scanner (ej. `"token": "abcdef1234567890abcdef"`).
  2. Abrir un PR y observar el resultado del check `memory-mcp-validate`.
  3. Verificar si GitHub permite mergear el PR pese al `::warning::` emitido.
- **Resultado esperado:** dado que el job tiene `continue-on-error: true`, el check debería figurar como no-bloqueante independientemente del resultado del script.
- **Resultado obtenido:** **No ejecutado** — requiere abrir un PR de prueba con contenido sintético; se marca como prueba a ejecutar, no simulada, para no insertar datos falsos en el repo sin autorización.
- **Evidencia requerida:** captura del check run en GitHub mostrando `continue-on-error` y el resultado del merge.
- **Severidad:** Media-Alta.
- **Probabilidad e impacto:** Alta probabilidad de que el comportamiento sea el esperado por el propio YAML (`continue-on-error: true` es una directiva explícita y confiable de GitHub Actions); impacto si se confirma: ningún secreto real quedaría bloqueado por este control.
- **Recomendación concreta:** Decidir explícitamente si este control debe ser bloqueante. Si el objetivo es solo "avisar", documentarlo como tal en `CLAUDE.md` para que nadie asuma protección real. Si el objetivo es prevenir secretos en el repo, quitar `continue-on-error: true` (o acotarlo a los pasos no críticos) y considerar ampliar el escaneo a todo el repositorio.
- **Criterio de cierre verificable:** Definición explícita y documentada de la política (bloqueante vs. informativo), reflejada correctamente en el YAML.
- **Estado:** **Pendiente** (requiere ejecución en PR de prueba con autorización, no se ejecuta de oficio para evitar introducir contenido sintético sin aprobación).

### Caso T-03 — Validar JSON de `.mcp.json`

- **Área/componente:** `.mcp.json`.
- **Objetivo:** Confirmar que el archivo es JSON válido (lo que el propio CI ya valida en cada push/PR).
- **Procedimiento reproducible:** `python3 -c "import json; json.load(open('.mcp.json'))"`.
- **Resultado obtenido:** `[HECHO]` Ejecutado localmente en esta auditoría — el archivo es JSON válido, sin errores de sintaxis.
- **Evidencia:** ejecución sin excepción.
- **Severidad:** Informativa.
- **Recomendación:** Ninguna acción requerida sobre este punto puntual.
- **Criterio de cierre:** Cumplido.
- **Estado:** **Validado.**

### Caso T-04 — Verificar pin de versión del paquete MCP

- **Área/componente:** `.mcp.json`, dependencia `@modelcontextprotocol/server-memory`.
- **Objetivo:** Determinar si la versión ejecutada es reproducible entre sesiones.
- **Procedimiento reproducible:** Inspeccionar el campo `args` de `.mcp.json`: `["-y", "@modelcontextprotocol/server-memory"]` — sin sufijo de versión (`@x.y.z`) ni lockfile en el repo.
- **Resultado obtenido:** `[HECHO]` Confirmado — no hay pin de versión ni lockfile.
- **Severidad:** Media.
- **Riesgo:** Cambios de comportamiento no controlados si el paquete publica una nueva versión con breaking changes; superficie de supply-chain (ejecuta código de un paquete de terceros vía `npx -y` sin intervención humana).
- **Recomendación concreta:** Pinear a una versión específica (`@modelcontextprotocol/server-memory@<versión exacta>`) y actualizarla de forma deliberada, no automática.
- **Criterio de cierre verificable:** `.mcp.json` referencia una versión explícita; revisión periódica documentada.
- **Estado:** **Validado (hallazgo confirmado).**

### Caso T-05 — Prueba de restauración del backup del knowledge-graph

- **Área/componente:** Persistencia de memoria / continuidad ante pérdida de contenedor.
- **Objetivo:** Confirmar que, si el contenedor se recicla, el contenido de memoria sobrevive vía git.
- **Procedimiento reproducible:** Requiere un ciclo real de reciclado de contenedor con contenido no vacío en el knowledge-graph, commit del mismo, y verificación post-reciclado. No ejecutable dentro de esta sesión.
- **Resultado obtenido:** No ejecutado — `[BLOQUEADO]` requiere ventana operativa y no puede simularse de forma confiable en una sola sesión.
- **Severidad:** Media (el archivo está vacío hoy, por lo que el riesgo actual es bajo, pero la propiedad no está probada).
- **Recomendación:** Ejecutar la prueba la próxima vez que el knowledge-graph tenga contenido real, documentando el resultado.
- **Criterio de cierre:** Restauración exitosa documentada al menos una vez.
- **Estado:** **Bloqueado** (requiere condiciones que no se dan en esta sesión).

---

## 8. Hallazgos confirmados

| ID | Hallazgo | Severidad | Evidencia | Estado |
|---|---|---|---|---|
| H-01 | Ruta hardcodeada de `MEMORY_FILE_PATH` no existe en este entorno (ENOENT) | Alta | `ls` fallido, ver T-01 | Validado |
| H-02 | CI de validación es no-bloqueante (`continue-on-error: true`) | Media-Alta | Lectura directa del YAML | Validado |
| H-03 | Escaneo de secretos con cobertura parcial (solo un archivo) | Media | Lectura directa del YAML | Validado |
| H-04 | Dependencia MCP sin pin de versión ni lockfile | Media | Lectura directa de `.mcp.json` | Validado |
| H-06 | El repositorio no contiene la aplicación "pagina-oro-loader" que su nombre sugiere | Crítica para el objetivo de auditoría del "programa", no para el repo | `git log --all`, listado de archivos | Validado (gap de alcance) |

---

## 9. Inferencias y riesgos potenciales

| # | Inferencia / riesgo | Base | Confianza |
|---|---|---|---|
| 1 | `[INFERENCIA]` H-01 es probablemente la causa (o una causa contribuyente) de H-05 (inestabilidad del servidor `memory` observada en esta sesión) | Un `ENOENT` al iniciar el proceso del servidor MCP es una causa típica de que un servidor stdio no llegue a exponer sus tools de forma estable | Media — no confirmado con logs del propio servidor MCP, que no están accesibles desde esta sesión |
| 2 | `[RIESGO]` Si en algún momento se sube a este repo el código real de "pagina-oro-loader.html" sin pasar por este mismo pipeline de CI, quedaría sin ningún control automático (ni de secretos, ni de sintaxis, ni de tests) | El único workflow existente audita exclusivamente `.mcp.json` y el knowledge-graph | Alta (estructural, no depende de una prueba puntual) |
| 3 | `[RIESGO]` Ausencia de `LICENSE`, `README.md` funcional y política de contribución puede generar ambigüedad operativa si el repo escala con más colaboradores | No se encontró ninguno de estos archivos | Media |
| 4 | `[SUPOSICION]` El usuario probablemente espera que esta auditoría cubra también el `index.html` local mencionado anteriormente en la conversación, que no está en este repo | Contexto conversacional previo | Alta como hipótesis de intención, pero no verificable sin que el usuario lo confirme o suba el archivo |

---

## 10. Plan de remediación priorizado

| Prioridad | ID | Acción | Responsable sugerido | Evidencia de cierre | Criterio de cierre |
|---|---|---|---|---|---|
| 1 (Alta) | H-01 | Corregir `MEMORY_FILE_PATH` para que resuelva correctamente en el entorno real, o documentar el procedimiento de ajuste manual por entorno + agregar verificación automática que falle visiblemente si no resuelve | Owner del repo / mantenedor de `CLAUDE.md` | Ejecución de T-01 sin error en una sesión nueva | `ls` sobre la ruta configurada resuelve sin error |
| 2 (Media-Alta) | H-02 | Decidir y documentar explícitamente si el CI debe ser bloqueante; ajustar `continue-on-error` en consecuencia | Owner del repo | YAML actualizado + PR de prueba (T-02) mostrando el comportamiento esperado | Comportamiento del CI coincide con la política documentada |
| 3 (Media) | H-04 | Pinear versión de `@modelcontextprotocol/server-memory` en `.mcp.json` | Owner del repo | Diff del `.mcp.json` con versión explícita | Ejecuciones sucesivas usan la misma versión verificablemente |
| 4 (Media) | H-03 | Evaluar ampliar el escaneo de secretos a todo el repositorio (o justificar por qué el alcance actual es suficiente) | Owner del repo / seguridad | YAML actualizado o nota de decisión documentada | Escaneo cubre el alcance decidido, documentado |
| 5 (Media) | H-06 | Definir dónde vive realmente el código de "pagina-oro-loader" y, si corresponde, incorporarlo a este repositorio o vincular el repo correcto a la sesión | Usuario / owner de producto | Repo conectado o archivo subido | Auditoría funcional del "programa" puede ejecutarse con evidencia real |
| 6 (Baja) | — | Agregar `README.md` explicando el propósito del repositorio | Owner del repo | Archivo creado | Archivo presente y accesible |

---

## 11. Criterios de salida a producción

`[HECHO]` **No existe una aplicación de producción en este repositorio** sobre la cual emitir un veredicto de apto/no apto en el sentido funcional del pedido.

**Veredicto sobre lo que sí existe (tooling de memoria MCP + CI):**

> **Apto con condiciones.**

Condiciones para levantar la reserva:
1. Resolver H-01 (ruta de memoria persistente) y verificarlo en al menos una sesión nueva.
2. Decidir y documentar explícitamente la política de bloqueo del CI (H-02).
3. Pinear versión de la dependencia MCP (H-04).

**Veredicto sobre el objetivo original ("auditar el programa"):**

> **No aplica / no ejecutable con la evidencia disponible.** No es un "no apto" del programa — es la ausencia del objeto de auditoría en este repositorio. Se requiere el insumo de la sección 12 para poder emitir cualquier veredicto funcional.

---

## 12. Preguntas bloqueantes y próximos pasos

| # | Pregunta bloqueante | Por qué es necesaria |
|---|---|---|
| 1 | ¿Dónde vive el código real de "pagina-oro-loader.html" / el `index.html` mencionado antes en la conversación — es otro repositorio de GitHub, o solo un archivo local en tu PC que aún no se subió a ningún repo? | Sin esto no se puede auditar frontend, backend, APIs, BD, auth, ni ningún ítem funcional del checklist de la sección 6 |
| 2 | Si es otro repositorio: ¿puedo conectarlo a esta sesión (`add_repo`) para auditarlo directamente? | Habilitaría una auditoría real de código, en vez de un plan teórico |
| 3 | ¿La corrección de H-01 (ruta de memoria) se autoriza para ejecutarse ahora, o preferís revisarla vos primero? | Es un cambio de configuración de bajo riesgo pero toca un archivo ya documentado como "bug confirmado" — se prefiere confirmación antes de tocarlo de nuevo |
| 4 | ¿Se autoriza abrir un PR de prueba sintético para ejecutar el caso T-02 (verificar si el CI realmente no bloquea un secreto)? | Requiere insertar contenido sintético temporal en una rama, que se recomienda hacer solo con autorización explícita |
| 5 | ¿Existe algún ambiente de staging/producción vinculado a este proyecto sobre el que deba evaluarse infraestructura, backups y monitoreo? | Sin esto, esas secciones del checklist quedan como plan, no como auditoría ejecutada |

**Próximos pasos sugeridos (en orden):**
1. Responder la pregunta bloqueante #1 — es la que desbloquea el resto de la auditoría funcional.
2. Autorizar (o no) la corrección de H-01.
3. Definir política de CI (bloqueante vs. informativo) para H-02.
4. Si aparece código de aplicación real, re-ejecutar esta auditoría usando el checklist de la sección 6 como marco completo.

---

*No puedo confirmar con la información disponible en esta sesión cuál es el estado de una aplicación "pagina-oro-loader.html" fuera de este repositorio, ni el estado de branch protection en GitHub, ni el comportamiento exacto del CI ante un secreto real sin ejecutar la prueba correspondiente. Estos puntos quedan marcados como pendientes, no como hallazgos asumidos.*
