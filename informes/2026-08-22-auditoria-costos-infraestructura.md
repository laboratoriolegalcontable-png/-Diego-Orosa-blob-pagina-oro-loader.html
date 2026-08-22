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

### Acción ejecutada — [ACTUALIZACIÓN 2026-08-22 04:02 UTC]

Aprobada por el usuario ("Si baja costos"). Se abrió y está en revisión:
**PR #1134 en `Diego-Orosa`** —
[chore(infra): bajar frecuencia de model-router-ovh-guards de cada 2hs a
cada 6hs](https://github.com/laboratoriolegalcontable-png/Diego-Orosa/pull/1134)
(draft). Cambia únicamente `cron: '17 */2 * * *'` → `cron: '17 */6 * * *'`
— de 12 corridas/día a 4/día (-66%), sin tocar los triggers de
`pull_request` ni `workflow_dispatch` ni la lógica de auto-reparación.
Verificado byte a byte contra el original antes de abrir el PR. Falta
mergearlo.

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

## 5. Make.com — [VERIFICADO] plan, pendiente detalle de escenarios

Organización: **Pro**, zona `us2.make.com`.

- **240.000 operaciones/mes** incluidas en el plan
- 20.971.520 (20MB) de tamaño de data store
- Retención de logs: 30 días

El team tiene una cantidad grande de escenarios activos (más de 3.000 líneas
de datos al listarlos, no cupo en un solo llamado). Mandé ese análisis a un
proceso en segundo plano para identificar cuáles son los escenarios que más
operaciones consumen y cuáles parecen duplicados/de prueba — **lo agrego a
este informe apenas termine** (probablemente en el próximo mensaje).

Lo que ya sabemos por vos: tenés **n8n disponible** como alternativa
self-hosted, y la idea es migrar los flujos de Make ahí para bajar el costo
recurrente de licencia. Con el detalle de escenarios que traiga el análisis
en curso, te digo cuáles migrar primero (los que más operaciones consumen)
y cuáles simplemente dar de baja porque no se usan.

---

## 6. OVH — dato tuyo confirmado, falta inventario

**[DATO DEL USUARIO]** ~$32-35 USD/mes.

No tengo conector a OVH desde esta sesión, así que no puedo ver qué corre
ahí. Encontré que existe un repo `orosa-ovh-control` en tu cuenta de GitHub
(lo agregué a esta sesión mientras armaba este informe) — dice referencias a
"capacidad OVH pendiente de acceso al repo orosa-ovh-control" en commits
recientes del repo Diego-Orosa, lo que sugiere que ya hay trabajo en curso
ahí sobre esto mismo.

**Para completar esta parte del informe, necesito:**
1. Plan exacto contratado (VPS/dedicado, specs)
2. Qué corre ahí ahora (si tenés acceso SSH, corré `docker ps -a` o
   `systemctl list-units --type=service --state=running` y pasame el output)
3. Si el "servidor nuevo" 24/7 del que hablás (la desktop que dejaste
   prendida) **reemplaza** al OVH o es algo **adicional**

Sobre la idea de "explotar" la desktop 24/7 nueva: tiene sentido para la
memoria unificada (WSL, ya documentado en el informe del 2026-08-22 de
arquitectura de memoria) y para cargas de trabajo que no necesitan estar
expuestas a internet — pero **no reemplaza automáticamente a OVH** si algo
en OVH necesita responder desde una IP pública fija 24/7 (bots de WhatsApp,
webhooks de Make, un sitio con dominio propio). Antes de mover algo de OVH a
la desktop, confirmemos qué de lo que corre en OVH realmente necesita IP
pública fija.

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
