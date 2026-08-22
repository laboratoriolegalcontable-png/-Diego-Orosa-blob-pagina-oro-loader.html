# Auditoría de costos de infraestructura — Estudio Oro / ecosistema Orosa

**Fecha:** 2026-08-22
**Pedido por:** Diego Orosa, vía sesión de Claude Code
**Método:** conexión directa a las cuentas reales (Supabase, Vercel, Make.com,
GitHub) vía MCP autenticado en esta sesión. Todo lo marcado **[VERIFICADO]**
salió de una llamada real a la API del servicio. Todo lo marcado
**[VERIFICAR]** es algo que no pude confirmar desde acá (sin conector de
facturación) y necesito que lo saques vos del panel correspondiente.

> Nota: este informe se guarda en este repo (`-diego-orosa-blob-pagina-oro-loader.html`)
> como registro documental general, siguiendo el mismo criterio que el informe
> de arquitectura de memoria del 2026-08-22 — no es parte del código de este
> proyecto puntual.

---

## 1. Resumen ejecutivo

| Servicio | Costo mencionado | Estado real encontrado | Prioridad de acción |
|---|---|---|---|
| GitHub Actions | ~$75 gastados | **Causa raíz identificada**: 1 workflow corriendo cada 2hs 24/7 + 5 workflows más por cada PR, en un repo con 16.658 runs acumulados | 🔴 Alta — accionable ya |
| Vercel | "un poco más" que Supabase | 31 proyectos, 28 sin repo linkeado, patrones de duplicados evidentes | 🟡 Media — limpieza, no urgencia de costo |
| Supabase | ~$75 gastados | Plan Pro, 5 proyectos, 1 **INACTIVE** sin decisión tomada | 🟡 Media — decidir el proyecto inactivo |
| Make.com | mencionado, migrar a n8n | Plan Pro, 240.000 operaciones/mes incluidas | 🔵 Pendiente detalle de uso real (ver §5) |
| OVH | ~$32-35/mes (dato tuyo) | No tengo conector — necesito inventario de qué corre ahí | ⚪ Necesito datos tuyos |
| Whapi (ex "Wappy") | por reemplazar | Confirmado: reemplazo planeado por Wasender o API oficial de Meta | ⚪ Decisión ya tomada, solo ejecutar |

---

## 2. GitHub Actions — la causa que más gastó, y ya la encontré

**[VERIFICADO]** Repo `laboratoriolegalcontable-png/Diego-Orosa`: **16.658
ejecuciones de Actions** en total (`list_workflow_runs`, `total_count`).

Cada push o PR contra ese repo dispara **6 workflows en simultáneo**:

1. `memory-mcp-validate.yml`
2. `orosa-ci.yml` ("OROSA CI (isolated)")
3. `model-router-ovh-guards.yml` ("Runtime guards — Model Router y OVH")
4. `neon-branch-preview.yml` ("Create/Delete Branch for Pull Request")
5. `claude-security-review.yml` ("Claude Security Review")
6. `repo-sanity-check.yml` ("Repo Sanity Check")

**El hallazgo más importante:** `model-router-ovh-guards.yml` tiene esto en
su trigger:

```yaml
on:
  schedule:
    - cron: '17 */2 * * *'   # cada 2 horas, 24/7, para siempre
```

Eso son **12 ejecuciones por día, 365 días al año**, corran o no corran
cambios de código — solo para chequear que el Model Router (una función
Supabase) y el servidor OVH sigan respondiendo. Cada corrida instala Node,
corre tests, y en caso de falla intenta auto-reparar desplegando la función
de nuevo vía Supabase CLI.

Además encontré, en el propio historial de commits del repo, que **este
mismo problema ya se detectó antes** — hay commits con mensajes como:

- *"chore(infra): fija regla permanente de costos en Actions"*
- *"chore(infra): optimiza costos de GitHub Actions"*

Es decir: alguien (otra sesión de Claude, probablemente) ya intentó atacar
esto y el costo sigue sin bajar del todo, o el guard de cron se agregó
*después* de esos commits y volvió a subir el consumo.

**[VERIFICAR]** No tengo acceso a la facturación exacta de GitHub Actions
(no hay endpoint de billing en las herramientas que tengo conectadas). Para
confirmar el número exacto: **Settings → Billing and plans → Actions**, en la
cuenta de GitHub. Ahí vas a ver minutos consumidos este mes y el desglose por
repo.

### Acción ejecutada y mergeada — [ACTUALIZACIÓN 2026-08-22 04:20 UTC]

Aprobada por el usuario ("Si baja costos"). **PR #1134 en `Diego-Orosa`
mergeado** (squash, commit `23d01b1`) —
[chore(infra): bajar frecuencia de model-router-ovh-guards de cada 2hs a
cada 6hs](https://github.com/laboratoriolegalcontable-png/Diego-Orosa/pull/1134).
Cambia únicamente `cron: '17 */2 * * *'` → `cron: '17 */6 * * *'`
— de 12 corridas/día a 4/día (-66%), sin tocar los triggers de
`pull_request` ni `workflow_dispatch` ni la lógica de auto-reparación.
Verificado byte a byte contra el original antes de abrir el PR. **Ya está
en producción.**

- **(Pendiente, no ejecutado)** evaluar si `claude-security-review.yml` y
  `repo-sanity-check.yml` necesitan correr en TODOS los PR, o si alcanza
  con que corran solo contra la rama principal o antes de mergear a
  producción.
- **Evaluar si `claude-security-review.yml` y `repo-sanity-check.yml`
  necesitan correr en TODOS los PR**, o si alcanza con que corran solo contra
  la rama principal o antes de mergear a producción.
- Repo `Diego-Orosa` es **privado** — confirmá en Settings → Billing si la
  org está en un plan con minutos incluidos limitados; si es así, cada
  corrida extra de estos 6 workflows por PR consume del pool pago.

---

## 3. Supabase — [VERIFICADO] datos reales de tu cuenta

Organización: `estudiooro@estudiooro.com's Org`, plan **Pro**.

| Proyecto | Región | Estado |
|---|---|---|
| estudiooro's Project | us-west-2 | ACTIVE_HEALTHY |
| reclamai | sa-east-1 | ACTIVE_HEALTHY |
| **lexnova** | sa-east-1 | **INACTIVE** ⚠️ |
| estudio-oro-db | sa-east-1 | ACTIVE_HEALTHY |
| scrapling-crm | sa-east-1 | ACTIVE_HEALTHY |

**Acción concreta:** `lexnova` está inactivo. Un proyecto pausado en plan Pro
puede seguir facturando compute según hace cuánto está así. Decidilo ya:
¿lo reactivás, lo borrás, o confirmás que está pausado a propósito?

**[VERIFICAR]** El desglose de facturación exacto (compute hours, storage,
egress por proyecto) no lo puedo ver desde acá — está en **Organization →
Billing → Invoices** dentro del dashboard de Supabase. Con esa captura te
digo con precisión cuál de los 5 proyectos es el que más está pesando.

---

## 4. Vercel — [VERIFICADO] datos reales de tu cuenta

Team: `laboratoriolegalcontable-1926's projects`, plan **Pro**.

**31 proyectos** en la cuenta, de los cuales solo **3 están linkeados a un
repo de GitHub activo** (`reclamai`, `diego-orosa`, `orogest-restore`) — los
otros **28 no tienen link a repo**, señal de deploys sueltos o manuales.

Patrones de duplicados evidentes en los nombres:

- **Familia "arq"** (5 proyectos): `arq`, `arq3`, `arqfinal`, `arqdeploy4`,
  `arquitecto-oro`
- **Familia "estudio(o)ro"** (5 proyectos): `estudiooro-final`,
  `estudiooro-deploy`, `estudiooro-app`, `estudiooro-web`, `estudio-oro`
- **Familia "conclave"** (2 proyectos): `conclave-oro`, `conclave-app`
- Sueltos que también parecen tests: `deploy-oro`, `orodesk`, `oro-bot`

Vercel Pro no cobra por cantidad de proyectos en sí (cobra por uso: builds,
funciones, ancho de banda) — pero 28 proyectos sin repo linkeado es limpieza
pendiente igual: si alguno tiene un cron/webhook pegado sigue corriendo y
sumando uso sin que lo estés usando.

**Acción recomendada:** antes de borrar nada, revisar cuál de la familia
"arq" y "estudio(o)ro" es la versión real en producción (probablemente
`diego-orosa`, que sí está linkeada) y eliminar el resto.

---

## 5. Make.com — [VERIFICADO] plan y detalle completo de escenarios

Organización: **Pro**, zona `us2.make.com`.

- **240.000 operaciones/mes** incluidas en el plan
- 20.971.520 (20MB) de tamaño de data store
- Retención de logs: 30 días

**47 escenarios en total**: **27 activos**, **20 inactivos/pausados**
(43%). De esos 20 inactivos, **13 tienen 0 operaciones registradas en toda
su historia** — nunca corrieron ni una vez. Total de operaciones acumuladas
de todos los escenarios (histórico, no mensual): ~20.779 — muy por debajo
del límite de 240.000/mes del plan, así que el costo de Make **no viene por
overage de operaciones**, viene directamente de la suscripción Pro en sí.

**Top 10 escenarios activos por uso real** (candidatos a migrar primero a
n8n, en orden de prioridad):

| Escenario | Operaciones | Frecuencia |
|---|---|---|
| Scheduler — Recordatorios Lucrecia Natalia Megan | 2.086 | indefinidamente |
| Kairos — Monitor estudiooro.com (cada 1h) | 1.530 | cada hora |
| OroAgentes — Meta Ads Campaign Manager | 1.366 | diario |
| Resumen diario — Lucrecia + Natalia | 1.366 | diario |
| Narakia Tools — Conversión de Documentos | 1.077 | inmediato (webhook) |
| Narakia Tools — OSINT Due Diligence | 1.077 | inmediato (webhook) |
| Narakia Tools — Scraping Automático de Leads | 1.077 | inmediato (webhook) |
| Narakia Tools — Transcripción Audios Largos | 1.077 | inmediato (webhook) |
| Diagnóstico Legal + Model Router → WhatsApp Diego | 1.064 | inmediato (webhook) |
| Paula — Arsenal IA Lead + Model Router → WhatsApp Diego | 1.064 | inmediato (webhook) |

**Candidatos a simplemente borrar en Make (sin migrar a nada — 0 operaciones
registradas, nunca se usaron):**

`Email contacto@estudiooro → Lucrecia + NARAKIA`, `Google Calendar — Crear
Meet (todos los agentes)`, `Lead Distribution — Derivadores Penales`, `Lead
Scraper — Envío WhatsApp Masivo`, `Lead Scraper WhatsApp — DIEGO (No
tocar)`, `Lucrecia → Crear Meet en Google Calendar`, `NARAKIA — Dashboard
Diario 8am`, `Newsletter → WhatsApp Bienvenida (Whapi)`, `Oráculo — Enviar
WhatsApp Whapi FIXED`, `OroAgentes — Agente Lead Webhook v2 (Penal +
Inmobiliario)`, `OroAgentes — Calendarizador de Turnos v2`, `Paula —
Asistente IA OroProp`, `ReclamAI — Captura Leads Consumidor → Planilla`,
`Redes Marketing — Reporte Semanal WhatsApp` (14 escenarios — nota: uno
dice explícitamente "No tocar" en el nombre, así que ese lo dejo para que
lo confirmes vos, no lo doy por muerto solo por tener 0 ops).

Otros inactivos con algo de uso histórico (revisar si siguen sirviendo o se
archivan): `bh-alerts → WhatsApp Diego (Whapi)` (519 ops), `Buenos días
Diego — mensaje personal diario` (282 ops), `Captación 1000 - Lead + Model
Router → WhatsApp Diego` (1.066 ops), `Narakia Tools — Monitor de
Competencia (Diario)` (397 ops), `NARAKIA Dreaming — Cron 03:00 ART` (9
ops), `Narakia — Claude API + web_fetch Legal` (7 ops).

**Recomendación:** dado que el costo de Make es la suscripción en sí (no
overage), migrar operaciones a n8n **no reduce el costo hasta que se dé de
baja el plan Pro de Make completo** — no tiene sentido migrar de a poco y
seguir pagando ambos en paralelo más de lo necesario. Sugerencia de plan:
(1) migrar primero los 10 de la tabla de arriba (son el 70% del uso real),
(2) confirmar con vos los 14 candidatos a borrar sin migrar, (3) una vez
migrado y confirmado lo demás, cancelar la suscripción Pro de Make.

---

## 6. OVH — [VERIFICADO 2026-08-22 04:35 UTC] inventario real, sin pedirte nada

Encontré el repo `laboratoriolegalcontable-png/orosa-ovh-control` — es el
control plane que Codex/Claude/Gemini usan para proponer y desplegar
recursos en el OVH sin tener acceso SSH directo (el servidor solo tiene una
deploy key de lectura y sincroniza `main` periódicamente). Ahí está
documentado, con evidencia real, qué corre y qué está solo propuesto:

**Confirmado operativo (con evidencia real, `reports/`):**
- **Oro Nexus 360** — modo demo, salud verificada (`/api/health` →
  `{"status":"ok","mode":"demo"}`), expuesto únicamente en
  `127.0.0.1:18787` (sin salir a internet), filesystem read-only, sin
  integraciones externas activas. Footprint mínimo.

**Aprobado pero NO confirmado operativo todavía** (`content/control-plane-status.md`
dice explícitamente "no declarado operativo — pendiente de que el
sincronizador del OVH lo levante y el operador confirme evidencia real"):

- **RealEstate360Ultra** — stack completo de 8 servicios Docker (postgres,
  redis, backend, frontend, ai-valuation, ai-nlp, mcp-server, pgadmin).
  Límites declarados: **6 CPU / ~4.25 GB RAM** en total si arranca todo.
  Imágenes propias pineadas por `@sha256` (no tags mutables), todo en
  `127.0.0.1` sin exposición externa.
- **Voicebox** — clonado/TTS de voz local (Whisper + multi-motor),
  **pensado para reemplazar a ElevenLabs** generando las voces de Lucrecia,
  Natalia y Megan sin pagarle a un proveedor externo. Límites: **2 CPU / 4
  GB RAM**. Puerto `127.0.0.1:17600`.
- **backup-pull-mirror** (`proposals/`, status `proposed`, todavía ni
  aprobado) — contenedor liviano que un cron diario usa para bajar un
  espejo de solo lectura del backup de Supabase (CRM, leads, causas,
  facturación, memoria de conversaciones) a un volumen local del OVH. Pedido
  explícito tuyo del 2026-08-21: **2 nodos de backup** — este OVH + una PC
  Ubuntu de oficina — para continuidad si Supabase o la conexión fallan. NO
  reemplaza a Supabase como fuente de verdad.

### Lo que esto significa para tu pregunta original ("¿para qué nos sirve el OVH?")

Hoy, confirmado, el OVH solo está cargando una demo liviana. Pero ya tiene
**aprobado** (no operativo aún) un stack de 8 CPU / ~8.25 GB RAM combinado
entre RealEstate360Ultra + Voicebox. Si esos dos se activan con tu plan
actual de ~$32-35/mes, es **muy probable que el servidor esté
subdimensionado** para eso — un VPS de esa gama normalmente no trae 8
núcleos ni 8GB de RAM libres. Antes de preocuparte por "bajar" el costo de
OVH, la pregunta real es al revés: **¿vas a activar RealEstate360Ultra y
Voicebox pronto?** Si sí, probablemente necesites *subir* de plan, no
bajarlo — y ahí el OVH deja de ser un candidato a recortar y pasa a ser
infraestructura que vale la pena, porque reemplaza suscripciones (ElevenLabs)
en vez de sumarlas.

**Confirmame:** ¿el plan actual de OVH ya tiene esos 8 CPU/8GB disponibles,
o hay que revisar el dimensionamiento antes de activar RealEstate360Ultra y
Voicebox?

Sobre la desktop 24/7 nueva (WSL): no reemplaza al OVH — cumple un rol
distinto (memoria unificada, cómputo que no necesita IP pública). El OVH sí
necesita seguir existiendo para lo que tiene que responder desde afuera
(el backup-pull-mirror, y eventualmente RealEstate360Ultra/Voicebox si se
exponen mediante el Nginx Proxy Manager que menciona el repo).

## 6.5. Otros cron excesivos en `Diego-Orosa` — [VERIFICADO] chequeado, nada más que arreglar

Revisé los otros 43 workflows del repo buscando el mismo patrón que
`model-router-ovh-guards.yml` (cron demasiado frecuente). Solo hay otros 4
con `schedule:`, y ninguno es un problema:

| Workflow | Cron | Frecuencia | Qué hace |
|---|---|---|---|
| `portal-check.yml` | `0 */6 * * *` | 4x/día | Login automático a portales judiciales (PJN, MEV, SCBA, AFIP/SRT, etc.) para chequear estado de causas |
| `audit-reclamai-daily.yml` | `0 9 * * *` | 1x/día | Auditoría diaria de CI/seguridad de la app ReclamaIA |
| `docs-skill-sync.yml` | `0 11 * * 1` | 1x/semana | Chequeo de desvío entre docs y skills instaladas |
| `orogest-weekly-update.yml` | `0 12 * * 1` | 1x/semana | Verifica que los links de directorios judiciales sigan respondiendo |

Ninguno corre por `push`/`pull_request` (solo por cron o manualmente), pero
las frecuencias son razonables — no hay otro "cada 2hs 24/7" escondido. No
se necesita tocar nada más acá.

---

## 7. Whapi (antes transcripto como "Wappy") — confirmado

**[VERIFICADO por vos]** Es tu proveedor de API de WhatsApp (tipo
Wati/Whapi). Plan: lo vas a dejar correr hasta que termine el período pago,
y después migrás a **Wasender** o a la **API oficial de Meta**.

No tengo conector a Whapi desde acá para ver el costo exacto. Cuando
definas la fecha de corte, avisame para que lo saque de la lista de "cosas a
vigilar" y lo demos por resuelto.

---

## 8. Repos de GitHub — sprawl real que también es costo (tiempo y Actions)

**[VERIFICADO]** Tu cuenta tiene **20 repositorios**. Varios son claramente
iteraciones sucesivas del mismo producto sin limpiar las anteriores:

- `OroGest-Platform`, `OroGest-Lex-v4`, `OroGest-v13`, `orogest-lex-backend`
  — 4 repos que parecen ser versiones distintas de OroGest
- `stack-ia-creador` (repo + proyecto Vercel con el mismo nombre)
- Forks sin actividad propia: `open-deep-research`, `last30days-skill`,
  `estudio-oro-legal-fork`
- Repos de nombre genérico sin contexto: `Nuevo`, `jddd`, `orow`

Cada uno de estos, si tiene Actions configurado igual que `Diego-Orosa` (6
workflows, uno con cron cada 2hs), multiplica el problema del punto 2. Vale
la pena revisar rápido cuáles de estos 20 tienen workflows con `schedule:`
corriendo sin que nadie los mire.

---

## 9.5. Hallazgo adicional (no relacionado al PR #1134) — checks rotos preexistentes en `Diego-Orosa`

Al revisar el CI del PR #1134 apareció un check en rojo, **"Workflows YAML
validos"** (parte del workflow `repo-sanity-check.yml`). Confirmado que
**no lo causó mi cambio**: el mismo check ya fallaba en el commit base
exacto (`7c7cd434`, del 21/08, un día antes de tocar nada), junto con otros
dos checks del mismo workflow (`JSON valido en todo el repo` y `Scan de
secrets hardcodeados`). Es decir: `repo-sanity-check.yml` viene fallando de
forma consistente desde antes — otro síntoma más del desorden general del
repo (44 workflows en `.github/workflows/`, no 6 como estimé en la sección
2 — subestimé bastante). No identifiqué el archivo YAML exacto que dispara
el error (el log de la corrida vieja ya expiró), pero no bloquea nada del
PR #1134. Queda como item de auditoría separado para una próxima pasada.

## 9. Próximos pasos

1. **Vos:** confirmame plan y servicios de OVH (§6) y el corte de fecha de
   Whapi (§7).
2. **Yo:** te aviso en cuanto termine el análisis detallado de escenarios de
   Make (§5) para decidir qué migrar a n8n primero.
3. **Juntos:** decidir qué hacer con `lexnova` (Supabase inactivo) y con los
   proyectos duplicados de Vercel — no voy a borrar nada sin que lo
   confirmes vos explícitamente.
4. **Acción de bajo riesgo que podés aprobar ya:** bajar la frecuencia del
   cron de `model-router-ovh-guards.yml` en `Diego-Orosa` de cada 2 horas a
   cada 6-8 horas. Es el cambio más chico con más impacto de costo que
   encontré en toda la auditoría.
