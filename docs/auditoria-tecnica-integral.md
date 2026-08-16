# Auditoría Técnica Integral

## Repositorio `-Diego-Orosa-blob-pagina-oro-loader.html`

| Campo | Detalle |
|---|---|
| **Documento** | Auditoría técnica integral — hallazgos, remediación y plan de auditoría funcional pendiente |
| **Versión** | 1.1 (incluye Anexo C — Registro de remediación) |
| **Fecha de emisión** | 2026-08-13 |
| **Ejecutado por** | Agente Claude Code, sesión asistida sobre el repositorio tal como está clonado en este entorno |
| **Clasificación** | Uso interno |
| **Estado** | Hallazgos H-01 a H-04 y H-08/H-09 remediados y verificados localmente; pendiente de confirmación en la primera ejecución real de GitHub Actions posterior al último push |

### Convención de etiquetas

| Etiqueta | Significado |
|---|---|
| `[HECHO]` | Verificado directamente en este entorno, con evidencia reproducible |
| `[INFERENCIA]` | Deducción razonable a partir de hechos, no un hecho en sí |
| `[RIESGO]` | Riesgo identificado, con severidad e impacto estimados |
| `[PENDIENTE]` | Requiere una acción o un insumo que no está disponible en esta sesión |
| `[SUPOSICION]` | Hipótesis explícita adoptada para interpretar un pedido ambiguo |

---

## 1. Resumen ejecutivo

`[HECHO]` A la fecha de esta auditoría, el repositorio no contiene una aplicación web, backend, base de datos, API ni frontend funcional. Su contenido consiste en: un archivo de configuración MCP (`.mcp.json`), un archivo de instrucciones de proyecto (`CLAUDE.md`), un archivo de memoria vacío (`.claude/memory/knowledge-graph.jsonl`), un workflow de CI de validación (`.github/workflows/memory-mcp-validate.yml`), un escáner de secretos versionado con su suite de tests (`scripts/scan_secrets.py`, `tests/test_scan_secrets.py`), y documentación de producto/negocio (`docs/*.md`).

`[HECHO]` No existe ningún `index.html` ni código de "página oro / loader" en este repositorio, pese a que su nombre lo sugiere. El historial completo de commits (`git log --all`) no muestra evidencia de que ese código haya existido aquí en ningún momento.

`[HECHO]` Se identificó, verificó y **corrigió** un defecto activo: la ruta configurada en `MEMORY_FILE_PATH` no coincidía con el directorio real de este entorno, lo que impedía al servidor MCP de memoria leer o escribir su archivo de persistencia. El detalle de la corrección y su verificación se documenta en el Anexo C.

`[SUPOSICION]` Se interpreta que el alcance de esta auditoría es el sistema disponible en este repositorio conectado a la sesión, y no un sistema externo (por ejemplo, el `index.html` local mencionado en un intercambio previo de esta conversación, al que este entorno no tiene acceso).

**Decisión de cierre (ver sección 11):** con la información disponible, no corresponde un veredicto de aptitud para producción, porque no existe una aplicación de producción que auditar en este repositorio. Lo que sí se entrega es: (a) auditoría completa de los componentes reales presentes, con hallazgos confirmados y remediados donde correspondía; y (b) un plan de auditoría exhaustivo y un checklist reutilizable para cuando exista código de aplicación real que auditar.

---

## 2. Alcance auditado y alcance pendiente

| Alcance | Estado | Detalle |
|---|---|---|
| Configuración MCP (`.mcp.json`) | `[HECHO]` Auditado y remediado | Ver H-01, H-04; detalle en Anexo C |
| Memoria persistente (`knowledge-graph.jsonl`) | `[HECHO]` Auditado | Archivo vacío (0 bytes) al momento de la auditoría |
| CI/CD (`memory-mcp-validate.yml`) | `[HECHO]` Auditado y remediado | Ver H-02, H-03, H-09; detalle en Anexo C |
| Escáner de secretos (`scripts/scan_secrets.py`) | `[HECHO]` Introducido y testeado en esta sesión | 7 tests de regresión en `tests/test_scan_secrets.py` |
| Documentación de proyecto (`CLAUDE.md`) | `[HECHO]` Auditado y actualizado | Ver H-01 |
| Documentos de producto/negocio (`docs/*.md`) | `[HECHO]` Revisados | No aplica auditoría técnica de sistema — son texto, no código ejecutable |
| Frontend / `index.html` / UI | `[PENDIENTE]` No auditable — no existe en este repositorio | Requiere que el código fuente se incorpore al repositorio, o que se conecte el repositorio/entorno donde reside |
| Backend / APIs | `[PENDIENTE]` No auditable — no existe | Ídem |
| Base de datos | `[PENDIENTE]` No auditable — no existe | Ídem |
| Autenticación / autorización / sesiones | `[PENDIENTE]` No auditable — no existe | Ídem |
| Infraestructura de despliegue (hosting, DNS, CDN) | `[PENDIENTE]` No auditable | No hay evidencia de dónde se despliega "pagina-oro-loader.html" |
| Gobernanza de la rama `main` (branch protection) | `[PENDIENTE]` No consultado | Requiere permisos de administración del repositorio en GitHub |
| Monitoreo / observabilidad de producción | `[PENDIENTE]` No auditable | No hay servicio en producción vinculado a este repositorio |
| Backups / recuperación ante incidentes de la aplicación | `[PENDIENTE]` No auditable | El único dato persistente versionado es el knowledge-graph, respaldado por el propio historial de git |
| Accesibilidad / UX / compatibilidad de navegador | `[PENDIENTE]` No auditable | No hay interfaz de usuario en este repositorio |
| Estabilidad de runtime del servidor MCP `memory` | `[RIESGO]` Observado, no aislado con certeza | El servidor apareció como "conectando" y luego figuró desconectado durante la sesión; ver H-05 |

---

## 3. Inventario de información disponible

| Ítem | Fuente | Estado |
|---|---|---|
| `.mcp.json` | Lectura íntegra | `[HECHO]` |
| `CLAUDE.md` | Lectura íntegra | `[HECHO]` |
| `.github/workflows/memory-mcp-validate.yml` | Lectura íntegra | `[HECHO]` |
| `.claude/memory/knowledge-graph.jsonl` | Lectura (vacío) | `[HECHO]` |
| Historial completo de git | `git log --all --oneline` | `[HECHO]` |
| Directorio de trabajo real del entorno | `pwd` | `[HECHO]` → `/home/user/-Diego-Orosa-blob-pagina-oro-loader.html` |
| Runtime de Node/npx | `which npx node && node --version` | `[HECHO]` → Node v22.22.2 |
| Versión real del servidor MCP de memoria | Respuesta `initialize` del protocolo MCP, capturada durante la verificación de H-01 | `[HECHO]` → `0.6.3` |
| Ejecución real de CI de GitHub Actions sobre los commits de esta sesión | `list_workflow_runs` / `get_job_logs` | `[HECHO]` — incluyó una corrida fallida que originó H-09 |
| Estado de branch protection en GitHub | No consultado; requiere permisos administrativos no solicitados en esta sesión | `[PENDIENTE]` |
| Código fuente de "pagina-oro-loader" / `index.html` real | No presente en el repositorio ni en su historial | `[PENDIENTE]` — se solicita al usuario su ubicación real |
| Accesos a ambientes de staging/producción, logs, métricas | No provistos | `[PENDIENTE]` |

---

## 4. Datos que requieren verificación

| # | Dato | Relevancia | Estado |
|---|---|---|---|
| 1 | Ubicación real del código de la aplicación "pagina-oro-loader" | Sin este dato no es posible auditar el "programa" en sentido funcional | `[PENDIENTE]` — requiere respuesta del usuario o conexión de un repositorio adicional |
| 2 | Reglas de protección de la rama `main` (revisiones obligatorias, checks requeridos) | Determina si el nuevo comportamiento bloqueante del CI (H-02) es efectivamente exigido antes de mergear | `[PENDIENTE]` — requiere acceso administrativo al repositorio |
| 3 | Existencia de un pipeline de despliegue hacia algún hosting para este proyecto | Sin esto no es posible evaluar infraestructura, backups, monitoreo ni recuperación ante incidentes | `[PENDIENTE]` |
| 4 | Confirmación en GitHub Actions de que el CI bloquea efectivamente un secreto real | La verificación disponible es local, equivalente a los pasos del CI, pero no una corrida positiva contra un secreto real en GitHub | `[PENDIENTE]` — deliberadamente no ejecutado por instrucción del usuario (sin PRs sintéticos) |

---

## 5. Mapa de riesgos priorizados

| ID | Área | Riesgo | Severidad | Estado actual |
|---|---|---|---|---|
| H-01 | Memoria MCP / persistencia | Ruta hardcodeada en `.mcp.json` no coincidía con el directorio real del entorno, impidiendo la lectura/escritura del archivo de memoria | Alta | **Remediado y verificado** (Anexo C) |
| H-02 | CI/CD | El workflow de validación corría con `continue-on-error: true`, por lo que nunca bloqueaba un merge, aunque detectara un secreto o un JSON inválido | Media-Alta | **Remediado**; confirmación positiva en GitHub Actions pendiente (dato #4 de la sección 4) |
| H-03 | Seguridad / escaneo de secretos | El escáner cubría un único archivo (`knowledge-graph.jsonl`) y no el resto del repositorio | Media | **Remediado y verificado** (Anexo C) |
| H-04 | Dependencias / supply chain | `.mcp.json` invocaba el paquete MCP sin pin de versión ni lockfile | Media | **Remediado y verificado** (Anexo C) |
| H-05 | Estabilidad de servidores MCP | El servidor `memory` se observó inestable (conectando → desconectado) durante la sesión | Media | `[RIESGO]` — causa raíz no confirmada; ver inferencia en sección 9 |
| H-06 | Alcance del producto | El repositorio no contiene la aplicación que su nombre sugiere | Crítica para el objetivo de auditar "el programa"; no aplica al repositorio en sí | Sin resolver — requiere decisión de producto, no una corrección técnica |
| H-07 | Gobernanza de branch protection | No verificado si `main` exige revisión o checks obligatorios antes de mergear | No evaluable con las herramientas disponibles en esta sesión | `[PENDIENTE]` |
| H-08 | Higiene de repositorio | Ausencia de `.gitignore`; se generaron artefactos de bytecode Python (`__pycache__/*.pyc`) durante la ejecución local de tests | Baja | **Remediado** — `.gitignore` agregado |
| H-09 | Falso positivo del propio escáner de secretos | La ampliación de cobertura de H-03 provocó que el escáner se detectara a sí mismo, bloqueando el CI con un falso positivo | Alta (bloqueaba el propio pipeline) | **Remediado y verificado**, confirmado en una corrida real de GitHub Actions (Anexo C) |

---

## 6. Checklist maestro de auditoría por dominio

Este checklist constituye el marco completo a aplicar cuando exista código de aplicación real en el repositorio. Las filas marcadas `N/A (repo actual)` documentan que, a la fecha, no existe objeto de auditoría para ese dominio; no se completan con resultados no verificados.

| Dominio | Ítem de checklist | Estado en este repositorio |
|---|---|---|
| Requisitos | Especificación funcional documentada y trazable a pruebas | `N/A (repo actual)` |
| Arquitectura | Diagrama de componentes, límites de confianza, flujo de datos | `N/A (repo actual)` |
| Código fuente | Linters, formateo, complejidad ciclomática, cobertura de tests | Parcial — aplicado a `scripts/scan_secrets.py` (7 tests) |
| APIs | Contratos, versionado, límites de tasa | `N/A (repo actual)` |
| Frontend | Manejo de estado, XSS, CSP, sanitización de entradas | `N/A (repo actual)` |
| Backend | Validación de entrada, manejo de errores, idempotencia | `N/A (repo actual)` |
| Base de datos | Migraciones, integridad referencial, índices, backups | `N/A (repo actual)` |
| AuthN / AuthZ | Modelo de roles, expiración de sesión, rotación de credenciales | `N/A (repo actual)` |
| Secretos y configuración | Gestión fuera de código, escaneo automático, rotación | Aplicado — ver H-02, H-03, H-04, H-09 |
| CI/CD | Checks bloqueantes, aprobaciones requeridas, despliegue reproducible | Aplicado — ver H-02 |
| Infraestructura | Infraestructura como código, hardening, gestión de accesos | `N/A (repo actual)` |
| Performance | Carga, estrés, latencia bajo concurrencia | `N/A (repo actual)` |
| Resiliencia | Circuit breakers, reintentos, degradación controlada | `N/A (repo actual)` |
| Backups / DR | RTO/RPO definidos y probados con restauración real | `N/A (repo actual)` — el único dato persistente depende de git como respaldo, sin prueba de restauración documentada |
| Observabilidad | Logs estructurados, métricas, alertas accionables | `N/A (repo actual)` |
| Privacidad | Clasificación de datos personales, minimización, retención | `N/A (repo actual)` |
| Accesibilidad | WCAG, navegación por teclado, lectores de pantalla | `N/A (repo actual)` |
| Compatibilidad | Matriz de navegadores/dispositivos soportados | `N/A (repo actual)` |
| Integraciones externas | Manejo de fallas de terceros, timeouts, contratos | Parcial — dependencia de `npx` hacia el registro de npm; ver H-04 |
| Operación | Runbooks, guardias, gestión de incidentes | `N/A (repo actual)` |

---

## 7. Casos de prueba detallados y reproducibles

### Caso T-01 — Resolución de `MEMORY_FILE_PATH`

| Campo | Detalle |
|---|---|
| Área/componente | Servidor MCP `memory`, configuración en `.mcp.json` |
| Objetivo | Confirmar si la ruta absoluta configurada existe en el entorno de ejecución real |
| Procedimiento | (1) Ejecutar `pwd`. (2) Ejecutar `ls -la` sobre la ruta literal de `MEMORY_FILE_PATH` |
| Resultado esperado | El directorio existe y el archivo es escribible |
| Resultado obtenido (previo a la corrección) | `No such file or directory` — la ruta configurada no coincidía con el directorio real del entorno |
| Severidad | Alta |
| Recomendación | Corregir la ruta para que coincida con el entorno real; documentar el procedimiento de verificación por sesión |
| Criterio de cierre | `ls` sobre la ruta configurada resuelve sin error |
| Estado | **Validado. Corregido y reverificado — ver Anexo C.** |

### Caso T-02 — Comportamiento del CI ante un secreto detectado

| Campo | Detalle |
|---|---|
| Área/componente | `.github/workflows/memory-mcp-validate.yml` |
| Objetivo | Confirmar si un secreto agregado al repositorio impide el merge de un PR |
| Procedimiento | En una rama de prueba, agregar contenido que dispare la regex del escáner; abrir un PR; observar si el check bloquea el merge |
| Resultado esperado (configuración previa) | Dado `continue-on-error: true`, el check figuraría como no bloqueante independientemente del resultado |
| Resultado obtenido | No ejecutado con contenido sintético, por instrucción explícita del usuario. Verificación indirecta realizada: los mismos comandos que ejecuta el CI corren en verde localmente tras la corrección (ver Anexo C) |
| Severidad | Media-Alta |
| Recomendación | Ejecutar esta prueba con autorización explícita cuando se requiera una confirmación positiva completa |
| Criterio de cierre | Comportamiento del CI verificado en un PR con contenido sintético autorizado |
| Estado | **Pendiente de confirmación positiva en GitHub; verificación local equivalente completada.** |

### Caso T-03 — Validez de `.mcp.json`

| Campo | Detalle |
|---|---|
| Área/componente | `.mcp.json` |
| Objetivo | Confirmar que el archivo es JSON válido |
| Procedimiento | `python3 -c "import json; json.load(open('.mcp.json'))"` |
| Resultado obtenido | `[HECHO]` Sin errores de sintaxis |
| Severidad | Informativa |
| Estado | **Validado.** |

### Caso T-04 — Pin de versión del paquete MCP

| Campo | Detalle |
|---|---|
| Área/componente | `.mcp.json`, dependencia `@modelcontextprotocol/server-memory` |
| Objetivo | Determinar si la versión ejecutada es reproducible entre sesiones |
| Resultado obtenido (previo a la corrección) | `[HECHO]` Sin pin de versión ni lockfile |
| Severidad | Media |
| Recomendación | Pinear una versión exacta y actualizarla de forma deliberada |
| Estado | **Validado. Corregido y reverificado — ver Anexo C.** |

### Caso T-05 — Prueba de restauración del backup del knowledge-graph

| Campo | Detalle |
|---|---|
| Área/componente | Persistencia de memoria / continuidad ante pérdida de contenedor |
| Objetivo | Confirmar que el contenido de memoria sobrevive a un reciclado de contenedor, vía git |
| Procedimiento | Requiere un ciclo real de reciclado de contenedor con contenido no vacío en el knowledge-graph, commit del mismo, y verificación posterior |
| Resultado obtenido | No ejecutable dentro de esta sesión |
| Severidad | Media (riesgo actual bajo, dado que el archivo está vacío; la propiedad de recuperación no está probada) |
| Estado | **Bloqueado** — requiere condiciones que no se dan en esta sesión |

---

## 8. Hallazgos confirmados

| ID | Hallazgo | Severidad | Evidencia | Estado |
|---|---|---|---|---|
| H-01 | Ruta hardcodeada de `MEMORY_FILE_PATH` no coincidía con el entorno real | Alta | `ls` fallido, ver T-01 | Remediado y verificado |
| H-02 | CI de validación no bloqueante (`continue-on-error: true`) | Media-Alta | Lectura directa del YAML | Remediado |
| H-03 | Escaneo de secretos con cobertura parcial | Media | Lectura directa del YAML | Remediado y verificado |
| H-04 | Dependencia MCP sin pin de versión ni lockfile | Media | Lectura directa de `.mcp.json` | Remediado y verificado |
| H-06 | El repositorio no contiene la aplicación "pagina-oro-loader" que su nombre sugiere | Crítica para el objetivo de auditoría del "programa" | `git log --all`, inventario de archivos | Sin resolver — gap de alcance, no corregible desde este repositorio |
| H-09 | Falso positivo del escáner de secretos ampliado, detectado en una corrida real de GitHub Actions | Alta | Log de check `validate` fallido | Remediado y verificado |

---

## 9. Inferencias y riesgos potenciales

| # | Inferencia / riesgo | Base | Confianza |
|---|---|---|---|
| 1 | `[INFERENCIA]` H-01 fue probablemente causa contribuyente de H-05 | Un error `ENOENT` al iniciar el proceso de un servidor MCP stdio es una causa típica de inestabilidad en la exposición de sus herramientas | Media — no confirmado con logs propios del servidor, no accesibles desde esta sesión |
| 2 | `[RIESGO]` Si se incorpora a este repositorio el código real de "pagina-oro-loader" sin pasar por el pipeline actual, quedaría sin ningún control automático de calidad o seguridad | El único workflow existente audita `.mcp.json` y los archivos versionados por el escáner de secretos, no código de aplicación | Alta — estructural, no depende de una prueba puntual |
| 3 | `[RIESGO]` La ausencia de `LICENSE`, `README.md` funcional y política de contribución puede generar ambigüedad operativa si el repositorio incorpora más colaboradores | No se encontró ninguno de estos archivos | Media |
| 4 | `[SUPOSICION]` El usuario podría esperar que esta auditoría cubra también el `index.html` local mencionado en un intercambio previo, que no está en este repositorio | Contexto conversacional previo | Alta como hipótesis de intención; no verificable sin confirmación del usuario |

---

## 10. Plan de remediación priorizado

| Prioridad | ID | Acción | Responsable sugerido | Criterio de cierre | Estado |
|---|---|---|---|---|---|
| 1 | H-01 | Corregir `MEMORY_FILE_PATH` para el entorno real | Owner del repositorio | `ls` sobre la ruta configurada resuelve sin error | **Cerrado** |
| 2 | H-02 | Definir y aplicar política de bloqueo del CI | Owner del repositorio | Comportamiento del CI coincide con la política documentada | **Cerrado**; confirmación positiva en GitHub pendiente |
| 3 | H-04 | Pinear versión de la dependencia MCP | Owner del repositorio | Ejecuciones sucesivas usan la misma versión verificablemente | **Cerrado** |
| 4 | H-03 | Ampliar el escaneo de secretos a todo el repositorio | Owner del repositorio / seguridad | Escaneo cubre el alcance decidido, documentado | **Cerrado** |
| 5 | H-09 | Corregir el falso positivo del escáner sobre sí mismo | Owner del repositorio | Suite de tests y escaneo repo-real en verde, confirmado en GitHub Actions | **Cerrado** |
| 6 | H-06 | Definir dónde vive el código real de "pagina-oro-loader" e incorporarlo o vincularlo a la sesión | Usuario / owner de producto | Repositorio conectado o código incorporado | Abierto |
| 7 | — | Agregar `README.md` explicando el propósito del repositorio | Owner del repositorio | Archivo presente y accesible | **Cerrado** |

---

## 11. Criterios de salida a producción

`[HECHO]` No existe una aplicación de producción en este repositorio sobre la cual emitir un veredicto de aptitud en el sentido funcional del pedido original.

**Veredicto sobre el tooling existente (configuración MCP + CI):**

> **Apto con condiciones.** Las condiciones originales (H-01, H-02, H-04) fueron remediadas y verificadas localmente en esta sesión. Queda pendiente únicamente la confirmación positiva en una ejecución real de GitHub Actions de que el CI bloquea un secreto efectivo (dato #4 de la sección 4), no ejecutada por instrucción explícita del usuario.

**Veredicto sobre el objetivo original ("auditar el programa"):**

> **No aplica con la evidencia disponible.** No se trata de un veredicto de "no apto", sino de la ausencia del objeto de auditoría en este repositorio. Se requiere el insumo detallado en la sección 12 para emitir cualquier veredicto funcional.

---

## 12. Preguntas bloqueantes y próximos pasos

| # | Pregunta bloqueante | Relevancia |
|---|---|---|
| 1 | ¿Dónde vive el código real de "pagina-oro-loader.html" — otro repositorio de GitHub, o un archivo local aún no incorporado a ningún repositorio? | Sin esta definición no es posible auditar frontend, backend, APIs, base de datos ni autenticación |
| 2 | Si se trata de otro repositorio, ¿corresponde conectarlo a esta sesión para su auditoría directa? | Habilitaría una auditoría real de código en lugar de un plan teórico |
| 3 | ¿Existe algún ambiente de staging/producción vinculado a este proyecto sobre el que deba evaluarse infraestructura, backups y monitoreo? | Sin esto, esas secciones del checklist permanecen como plan, no como auditoría ejecutada |

**Próximos pasos sugeridos:**
1. Definir la ubicación real del código de aplicación (pregunta #1) — desbloquea la auditoría funcional completa.
2. Autorizar, si corresponde, la ejecución de un PR de prueba controlado para confirmar T-02 de forma positiva en GitHub Actions.
3. Ante la incorporación de código de aplicación real, reejecutar esta auditoría utilizando el checklist de la sección 6 como marco completo.

---

## Anexo A — Síntesis: hechos, inferencias, riesgos y pendientes

- **Hechos verificados:** todos los hallazgos H-01 a H-04, H-08 y H-09 cuentan con evidencia reproducible capturada en esta sesión (comandos ejecutados, respuestas de protocolo MCP, logs de GitHub Actions).
- **Inferencias:** la relación entre H-01 y H-05 (sección 9, ítem 1) es razonable pero no confirmada con logs internos del servidor MCP.
- **Riesgos abiertos:** H-05 (estabilidad del servidor de memoria) y H-06 (ausencia del código de aplicación) permanecen sin resolver al cierre de este documento.
- **Datos pendientes de verificación crítica:** confirmación positiva en GitHub Actions de que el CI bloquea un secreto real (sección 4, ítem 4); estado de branch protection sobre `main`; ubicación real del código de aplicación.

## Anexo B — Preguntas de validación sugeridas para una futura auditoría funcional

1. ¿Cuál es la arquitectura y el stack tecnológico de la aplicación real, una vez identificada su ubicación?
2. ¿Existen ambientes de staging y producción diferenciados, y quién administra sus accesos?
3. ¿Qué nivel de cobertura de tests automatizados tiene el código de aplicación, si existe?
4. ¿Existen incidentes previos documentados sobre esta aplicación que deban considerarse en el alcance de la auditoría?
5. ¿Qué datos personales o sensibles procesa la aplicación, si los procesa?

## Anexo C — Registro de remediación (2026-08-13)

Por instrucción explícita del usuario, se corrigieron H-01, H-02, H-03 y H-04 sobre este mismo repositorio, sin abrir PRs sintéticos ni auditar sistemas externos. Los hallazgos originales de las secciones 5, 7 y 8 permanecen documentados como registro histórico; este anexo detalla qué se hizo y cómo se verificó cada corrección.

### H-01 — Ruta de memoria persistente

`MEMORY_FILE_PATH` en `.mcp.json` se actualizó a `/home/user/-Diego-Orosa-blob-pagina-oro-loader.html/.claude/memory/knowledge-graph.jsonl`, la ruta real de este entorno, confirmada con `pwd`.

**Verificación:** se instanció manualmente el servidor `npx -y @modelcontextprotocol/server-memory` con esa variable de entorno y se envió una llamada `create_entities` de prueba por el protocolo MCP (stdio). Se confirmó que la entidad quedó escrita en el archivo. Previamente se probó una ruta relativa, que falló — resuelve contra el directorio interno del paquete npm instalado por `npx`, no contra el directorio del repositorio — alternativa descartada y documentada en `CLAUDE.md`. El archivo de memoria se revirtió a 0 bytes antes de commitear, para no dejar datos sintéticos de prueba en el repositorio.

**Evidencia:** respuesta de `create_entities` con resultado no vacío usando la ruta absoluta; error `ENOENT` explícito usando la ruta relativa; `wc -c` = 0 tras la reversión.

**Estado:** corregido y verificado.

### H-02 — CI no bloqueante

Se eliminó `continue-on-error: true` del job `validate` en `.github/workflows/memory-mcp-validate.yml`. Ambos steps (validación de JSON y escaneo de secretos) bloquean ahora el check.

**Verificación:** se ejecutaron localmente los mismos comandos que corre el CI contra el estado final del repositorio; los tres terminan en código de salida 0.

**Estado:** corregido. La confirmación positiva de que el CI bloquea un secreto real en una ejecución de GitHub Actions queda pendiente (no se ejecutó, por instrucción explícita del usuario, para evitar introducir contenido sintético sin autorización).

### H-03 — Cobertura del escaneo de secretos

El escaneo se extrajo de un script embebido en el YAML a `scripts/scan_secrets.py`, versionado y testeado, que recorre todos los archivos versionados por git (`git ls-files`) en lugar de un único archivo.

**Verificación:** ejecución contra el repositorio real sin coincidencias, código de salida 0. Un test dedicado confirma, sobre un repositorio git sintético en un directorio temporal, que el script detecta un secreto en un archivo distinto del knowledge-graph.

**Estado:** corregido y verificado.

### H-04 — Dependencia sin pin de versión

`.mcp.json` pinea ahora `@modelcontextprotocol/server-memory@0.6.3`, versión exacta observada en el campo `serverInfo.version` de la respuesta `initialize` capturada durante la verificación de H-01.

**Estado:** corregido y verificado.

### H-08 — Artefactos de bytecode sin ignorar (detectado durante la remediación)

Al ejecutar los tests localmente se generó `scripts/__pycache__/*.pyc`, un artefacto que no debía versionarse; el repositorio no contaba con un `.gitignore`.

**Acción:** se eliminó el bytecode generado y se agregó `.gitignore` (`__pycache__/`, `*.pyc`).

**Estado:** corregido.

### H-09 — Falso positivo del escáner sobre sí mismo (detectado en una corrida real de GitHub Actions)

El fix de H-03 rompió el propio CI: la regex original usaba un separador opcional entre la palabra clave y el valor, por lo que matcheaba como subcadena dentro de palabras en español que contienen accidentalmente "secret" — por ejemplo, "secreto" dentro del nombre de la función `test_detecta_secreto_con_prefijo_conocido` — sin que existiera un secreto real. Adicionalmente, los propios strings de prueba de `tests/test_scan_secrets.py`, usados para validar la regex, quedaron dentro del alcance ampliado del escaneo y también generaban coincidencias.

**Evidencia:** check `validate` fallido en la ejecución `31661138296` de GitHub Actions, con el mensaje `Posible secreto detectado en .../tests/test_scan_secrets.py: secreto_con_prefijo_conocido...`.

**Corrección:** la regex ahora exige un límite de palabra al inicio y un separador obligatorio (`[\"':= ]+` en lugar de opcional) entre la palabra clave y el valor; se agregó una exclusión explícita y documentada para `tests/test_scan_secrets.py` en el propio script. Se sumaron dos tests de regresión que cubren específicamente este caso.

**Verificación:** 7 de 7 tests en verde localmente; escaneo del repositorio real en código de salida 0.

**Estado:** corregido y verificado, incluyendo confirmación en una ejecución real de GitHub Actions posterior a la corrección.

### Explícitamente no ejecutado, por instrucción del usuario

- No se abrió ningún PR con contenido sintético. El caso T-02 permanece sin confirmación empírica positiva de que GitHub bloquea el merge ante un secreto real; lo verificado es que el script y los tests, ejecutados como lo haría el CI, se comportan según lo esperado.
- No se auditó ningún sistema externo a este repositorio. El `index.html` / "pagina-oro-loader" mencionado en la conversación permanece fuera de alcance; H-06 sigue sin resolver, por tratarse de una decisión de producto y no de una corrección técnica ejecutable desde este repositorio.

---

*Este documento no afirma la ausencia de errores ni una condición de seguridad absoluta sobre los componentes auditados. Todo punto sin evidencia directa se marca explícitamente como pendiente o como inferencia, y no como hallazgo confirmado.*
