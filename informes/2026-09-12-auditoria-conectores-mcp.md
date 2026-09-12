# Auditoría de conectores MCP activos — Estudio Oro

**Fecha:** 2026-09-12. **Fuente:** `ListConnectors` (API real de Claude.ai para esta cuenta), no memoria ni suposición. Sigue del punto de gobierno pendiente en `informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md` sección 4.3 ("evaluar un gateway único... en vez de conectar cada servicio suelto").

## Número real

**52 conectores** con `connected: true` y `enabledInChat: true` en `ListConnectors` — recontado explícitamente (no a ojo) tras un hallazgo real de `cubic`: mi primer conteo decía "51" y no era reproducible contra los propios datos que cito. **GitHub es una conexión de terceros adicional a esos 52** — llega a esta sesión por un mecanismo separado y no aparece en la respuesta de `ListConnectors`, así que el total real de conexiones de terceros activas es **53**, no 51. El MCP `memory` de este repo no se suma a ninguna de las dos cifras: es configuración local (`.mcp.json`), no un conector de cuenta. La cifra "~40"/"30+" que usé en el informe anterior era una estimación a ojo, muy por debajo de la real. Esto confirma en la práctica el hallazgo #1 del reporte de Docker: "operational complexity from orchestrating multiple components is the #1 challenge" (48% de las orgs).

**Limitación importante:** esta auditoría es de **relevancia** (¿tiene sentido que este conector esté prendido para un estudio jurídico/inmobiliario?), no de **uso real** — no tengo acceso a estadísticas de "última vez usado" por conector. Esa información solo la tiene el Doctor desde `claude.ai` → configuración de conectores. Lo que sigue son candidatos a revisar, no un veredicto.

## Núcleo confirmado (coincide con la infraestructura real declarada)

| Conector | Por qué es núcleo |
|---|---|
| Supabase | Proyecto real `moljmujlfvtsgkjbtwss` (preferencias del usuario) |
| Make | Cuenta real `2012148`, corre los 4 bots NARAKIA (ver `bots/manifest-narakia.md`) |
| Netlify | Sitio real `41afdafa` (preferencias del usuario) |
| GitHub | Repos reales de Estudio Oro/Diego Orosa |

## Legal research (encaja con la práctica penal)

CourtListener, Descrybe Legal Engine, Legal Data Hunter, Lawve AI — los 4 se solapan parcialmente en función (búsqueda de jurisprudencia/doctrina), pero cada uno cubre jurisdicciones o formatos distintos (CourtListener es EE.UU., Legal Data Hunter es multi-jurisdiccional, Lawve AI es un catálogo de skills). No es redundancia clara, es cobertura complementaria — dejar como está salvo que el Doctor confirme que solo usa uno.

## Hallazgo concreto #1 — dos backends de Postgres coexistiendo, uno sin validar

**Corregido tras hallazgo de `cubic`:** mi primera versión decía "no hay evidencia de uso de Neon" — es falso. `informes/2026-08-22-auditoria-costos-infraestructura.md` documenta que el repo `Diego-Orosa` corre un workflow de GitHub Actions llamado `neon-branch-preview.yml` ("Create/Delete Branch for Pull Request") en cada push/PR — un uso real de Neon para bases de datos de preview por pull request, no una prueba huérfana.

**Supabase** (el real, con proyecto ID conocido, para producción) **y Neon** (branches de preview por PR, según ese workflow) están conectados simultáneamente — y a diferencia de lo que dije antes, sí hay evidencia de que Neon cumple una función real, aunque distinta a la de Supabase (preview/CI vs. producción). **Recomendación: antes de tocar nada, confirmar si `neon-branch-preview.yml` sigue activo y en uso — si sí, Neon se queda conectado por esa razón puntual, no como redundancia; si el workflow ya no corre o quedó obsoleto, ahí sí desconectar.**

## Hallazgo concreto #2 — diez plataformas de hosting/apps conectadas a la vez

La arquitectura real declarada es **Netlify + Supabase + Make + React 18.3.1 CDN** (preferencias del usuario). Sin embargo, están conectados simultáneamente: Cloudflare Developer Platform, Railway, Replit, Vercel, Base44, Lovable, Wix, WordPress.com, WP Agent — **9 plataformas más**, además de Netlify. Esto es exactamente el patrón "multi-cloud, multi-plataforma no por decisión sino por acumulación" que el reporte de Docker describe como el precio de la flexibilidad sin gobierno. El informe de costos (`informes/2026-08-22-auditoria-costos-infraestructura.md`) ubica las experimentaciones nuevas del ecosistema en OVH, no en estas 9 — pero con matices que no había reflejado bien: **Oro Nexus 360** está confirmado operativo ahí; **RealEstate360Ultra** y **Voicebox** están *aprobados*, no confirmados operativos todavía. Ninguno de los tres depende de estas 9 plataformas según ese informe. **Recomendación: si ninguna de las 9 se está usando activamente para un proyecto concreto, desconectarlas reduce superficie de ataque sin perder nada.**

## Hallazgo concreto #3 — cinco canales de email conectados a la vez

Gmail, Resend, Mailrith, Hostinger Mail, y `mailerfind` (que además **falló la conexión en esta sesión**, error 502 — está roto, no solo sin uso) están todos conectados. Salvo que cada uno tenga un propósito específico distinto (ej. Gmail para leer, Resend para envíos transaccionales de una app), tener 5 vías de envío de mail aumenta la chance de mandar algo por el canal equivocado. **Recomendación: revisar cuál es el canal real de envío de Estudio Oro y desconectar el resto; en particular arreglar o quitar `mailerfind`, que está roto.**

## Hallazgo concreto #4 — cinco herramientas de ads/SEO conectadas a la vez

AdvisorPPC, HYPD AI, AdWhispr Ads, Windsor.ai, y Semrush cubren funciones que se solapan bastante (Google Ads, Meta Ads, SEO, analytics). El skill `ads-estudio-oro` menciona una cuenta real de Google Ads (575-636-8849) pero no dice cuál de estas 5 herramientas es la que efectivamente se usa para auditarla. **Recomendación: preguntarle al Doctor cuál de las 5 usa de verdad y desconectar las otras 4.**

## Hallazgo concreto #5 — conectores sin conexión aparente al negocio

- **PocketSmith Complete Access** (finanzas personales/presupuesto): no hay mención de esto en ningún informe del ecosistema Estudio Oro. Podría ser personal del Doctor (legítimo) o quedar de una prueba — no puedo saber cuál sin preguntar.
- **Metaview** (plataforma de reclutamiento con IA): no hay evidencia de que Estudio Oro esté contratando vía esta herramienta.
- **Zight MCP** (captura de pantalla/grabación): sin evidencia de uso declarado.
- **MercadoLibre**: sin conexión evidente a los 6 negocios declarados (ninguno vende en MercadoLibre según los informes existentes).

Ninguno de estos 4 es necesariamente un problema de seguridad por sí solo, pero cada uno es una credencial más conectada a esta cuenta sin un propósito documentado — exactamente el tipo de cosa que dificulta auditar qué puede hacer un agente en nombre de Diego.

## Lo que NO hace falta tocar

Todo lo que aparece como `connected: false` o `needs_reconnect` (LegalZoom, Linear) no está disponible para esta sesión — no representa riesgo activo. Los que muestran `installState: unknown` (Affinity, Aha!, Attention, BasicOps, Booking.com, Box, CoCounsel Legal, Egnyte, FactSet, Harness.io, Harvey, HyperFrames by HeyGen, Mailercloud, Midpage Legal Research, ms365, Ryze AI, S&P Global, Strava, Superhuman Mail, Ticket Tailor, Trellis, Xero) son un caso distinto — `unknown` significa que no se pudo chequear el estado, **no** que estén desactivados. No los traté como riesgo activo en esta auditoría, pero tampoco están confirmados como inofensivos; si alguno de estos nombres te suena familiar como algo que sí usás, avisame para verificarlo en `claude.ai` antes de asumir que está apagado.

## Próximo paso

Esta auditoría no puede ejecutar las desconexiones — eso se hace desde `claude.ai` → configuración de conectores, y es una decisión del Doctor, no algo para automatizar sin confirmación. Si el Doctor confirma cuáles de los 5 hallazgos de arriba quiere dar de baja, puedo dejarlo anotado acá como decisión tomada, pero la baja en sí la tiene que hacer él (o pedírmelo explícitamente conector por conector, ya que no tengo una herramienta para desconectar conectores desde esta sesión).
