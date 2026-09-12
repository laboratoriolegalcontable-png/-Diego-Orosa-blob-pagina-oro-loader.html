#!/usr/bin/env node
// Gateway único de MCP para este repo.
//
// Por qué existe: informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md
// y informes/2026-09-12-auditoria-conectores-mcp.md documentan 53 conexiones de
// terceros activas en la cuenta, cada una configurada y auditada por separado —
// exactamente el "operational complexity from orchestrating multiple components"
// que el reporte de Docker marca como el desafío #1 (48% de las orgs). Este
// gateway ataca la parte de ese problema que SÍ vive en este repo: los servidores
// MCP `command`/stdio de `.mcp.json` (hoy solo `memory`, pensado para crecer).
// En vez de que `.mcp.json` liste cada backend como una entry separada, lista UNA
// sola entry ("gateway") que a su vez spawnea y agrega los backends reales
// declarados en gateway.config.json — un solo punto para loggear, autorizar y
// versionar el acceso a todos ellos, sin tocar el código de cada backend.
//
// Qué NO hace (todavía): no toca los 53 conectores de cuenta (Supabase, Make,
// Netlify, etc.) — esos viven en claude.ai, fuera del alcance de este repo (ver
// informe de auditoría de conectores, sección "Próximo paso"). Este gateway solo
// agrega servidores `command`/stdio que este repo mismo declara.
//
// Protocolo: MCP sobre stdio es JSON-RPC 2.0 con un mensaje por línea (sin saltos
// de línea embebidos) — igual que ya usa @modelcontextprotocol/server-memory. El
// gateway habla ese mismo protocolo tanto "hacia arriba" (con el cliente MCP que
// lo invoca, ej. Claude Code) como "hacia abajo" (con cada backend), sin
// dependencias externas — todo con `child_process`/`readline` del propio Node,
// para no depender de `npm install` de un paquete de gateway.
//
// IMPORTANTE — stdout es sagrado: cualquier log de diagnóstico va a stderr. Un
// solo `console.log` con logging hacia stdout rompe el framing JSON-RPC hacia el
// cliente. Ver mcp-dockerize/SKILL.md para el mismo tipo de lección aplicada a
// Docker; acá el equivalente es "nunca mezcles logs con el protocolo".
//
// Ver .claude/gateway/README.md para cómo probarlo y cómo agregar un backend.

import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const CONFIG_PATH = path.join(__dirname, 'gateway.config.json');

function log(...args) {
  // Nunca console.log: iría a stdout y rompería el framing JSON-RPC del
  // protocolo hacia el cliente. Todo el diagnóstico va a stderr.
  console.error('[mcp-gateway]', ...args);
}

function loadConfig() {
  const raw = readFileSync(CONFIG_PATH, 'utf8');
  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed.backends) || parsed.backends.length === 0) {
    throw new Error(`gateway.config.json sin "backends" (o vacío) en ${CONFIG_PATH}`);
  }
  for (const b of parsed.backends) {
    if (!b.name || !/^[a-zA-Z0-9_-]+$/.test(b.name)) {
      throw new Error(`backend con "name" invalido o ausente: ${JSON.stringify(b)}`);
    }
    if (!b.command) {
      throw new Error(`backend "${b.name}" sin "command"`);
    }
  }
  return parsed.backends;
}

// --- Un "Backend" encapsula el proceso hijo y su propio canal JSON-RPC. ---
class Backend {
  constructor(cfg) {
    this.name = cfg.name;
    this.cfg = cfg;
    this.pending = new Map(); // id -> {resolve, reject}
    this.nextId = 1;
    this.tools = []; // cache de tools/list, sin prefijo
    this.ready = false;
    this.child = null;
  }

  start() {
    const env = { ...process.env, ...(this.cfg.env || {}) };
    this.child = spawn(this.cfg.command, this.cfg.args || [], {
      cwd: REPO_ROOT,
      env,
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    this.child.on('exit', (code, signal) => {
      log(`backend "${this.name}" salió (code=${code} signal=${signal})`);
      this.ready = false;
      for (const { reject } of this.pending.values()) {
        reject(new Error(`backend "${this.name}" salió antes de responder`));
      }
      this.pending.clear();
    });
    this.child.stderr.on('data', (chunk) => {
      // El stderr del backend es diagnóstico del backend, no del gateway —
      // lo repetimos con prefijo para no perderlo, pero nunca a stdout.
      process.stderr.write(`[backend:${this.name}] ${chunk}`);
    });

    const rl = createInterface({ input: this.child.stdout });
    rl.on('line', (line) => this._handleLine(line));

    return new Promise((resolve, reject) => {
      this.child.once('error', reject);
      // Si el proceso ni siquiera arranca (comando inexistente), rechazar rápido.
      setTimeout(resolve, 0);
    });
  }

  _handleLine(line) {
    if (!line.trim()) return;
    let msg;
    try {
      msg = JSON.parse(line);
    } catch (err) {
      log(`backend "${this.name}" mandó una línea no-JSON, ignorada: ${line.slice(0, 200)}`);
      return;
    }
    if (msg.id !== undefined && this.pending.has(msg.id)) {
      const { resolve, reject } = this.pending.get(msg.id);
      this.pending.delete(msg.id);
      if (msg.error) reject(new Error(msg.error.message || JSON.stringify(msg.error)));
      else resolve(msg.result);
    }
    // Notificaciones del backend (sin id) se ignoran por ahora — ningún backend
    // actual (memory) manda notificaciones que el gateway necesite reenviar.
  }

  _send(obj) {
    this.child.stdin.write(JSON.stringify(obj) + '\n');
  }

  request(method, params) {
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this._send({ jsonrpc: '2.0', id, method, params });
    });
  }

  notify(method, params) {
    this._send({ jsonrpc: '2.0', method, params });
  }

  async initialize(protocolVersion) {
    await this.request('initialize', {
      protocolVersion,
      capabilities: {},
      clientInfo: { name: 'oro-mcp-gateway', version: '0.1.0' },
    });
    this.notify('notifications/initialized', {});
    const { tools } = await this.request('tools/list', {});
    this.tools = tools || [];
    this.ready = true;
    log(`backend "${this.name}" listo — ${this.tools.length} tool(s): ${this.tools.map((t) => t.name).join(', ')}`);
  }

  async callTool(realName, args) {
    return this.request('tools/call', { name: realName, arguments: args });
  }
}

// --- Lado "hacia arriba": hablar MCP con quien invocó este gateway. ---
async function main() {
  const backendConfigs = loadConfig();
  const backends = new Map();

  for (const cfg of backendConfigs) {
    const b = new Backend(cfg);
    await b.start();
    backends.set(b.name, b);
  }

  // Placeholder de protocolVersion hasta que el cliente mande su initialize
  // real — se reemplaza por el valor que el cliente pida, y ESE es el que se
  // usa para inicializar los backends (mantiene coherencia de versión en toda
  // la cadena).
  let protocolVersion = '2024-11-05';
  let initPromise = null;

  // Guardar la PROMISE (no un booleano) es lo que evita la condición de carrera:
  // "notifications/initialized" dispara la inicialización sin esperarla, y si
  // el siguiente mensaje (ej. "tools/list") llega mientras todavía está en
  // curso, tiene que esperar esa misma promise en vuelo — no ver un flag ya en
  // true y seguir de largo contra un `tools` todavía vacío (bug real: la
  // primera versión de esta función marcaba "ya inicializado" ANTES de esperar
  // el Promise.all, así que una llamada concurrente pasaba de largo).
  function ensureBackendsInitialized() {
    if (!initPromise) {
      initPromise = Promise.all([...backends.values()].map((b) => b.initialize(protocolVersion)));
    }
    return initPromise;
  }

  function aggregatedTools() {
    const all = [];
    for (const b of backends.values()) {
      for (const t of b.tools) {
        all.push({ ...t, name: `${b.name}__${t.name}` });
      }
    }
    return all;
  }

  function resolveBackendAndTool(prefixedName) {
    const idx = prefixedName.indexOf('__');
    if (idx === -1) return null;
    const backendName = prefixedName.slice(0, idx);
    const realName = prefixedName.slice(idx + 2);
    const backend = backends.get(backendName);
    if (!backend) return null;
    return { backend, realName };
  }

  const rl = createInterface({ input: process.stdin });

  function reply(id, result) {
    process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, result }) + '\n');
  }

  function replyError(id, code, message) {
    process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, error: { code, message } }) + '\n');
  }

  // readline emite todas las líneas de un archivo/pipe pequeño de forma
  // síncrona y dispara 'close' apenas termina de leerlas — sin este tracking,
  // 'close' llega y mata los backends ANTES de que los handlers async de
  // 'line' (que hacen await contra ellos) terminen de procesar nada más que
  // la primera línea. Verificado con este mismo bug real al probar el
  // handshake completo (initialize+tools/list+tools/call en un solo archivo
  // de entrada): solo la respuesta del "initialize" llegaba a salir.
  const inFlight = new Set();

  rl.on('line', (line) => {
    const p = handleLine(line).catch((err) => log('error inesperado procesando línea:', err));
    inFlight.add(p);
    p.finally(() => inFlight.delete(p));
  });

  async function handleLine(line) {
    if (!line.trim()) return;
    let msg;
    try {
      msg = JSON.parse(line);
    } catch {
      log(`línea no-JSON del cliente, ignorada: ${line.slice(0, 200)}`);
      return;
    }

    // Notificaciones del cliente (sin id): no llevan respuesta.
    if (msg.id === undefined) {
      if (msg.method === 'notifications/initialized') {
        try {
          await ensureBackendsInitialized();
        } catch (err) {
          log(`error inicializando backends: ${err.message}`);
        }
      }
      return;
    }

    try {
      switch (msg.method) {
        case 'initialize': {
          protocolVersion = msg.params?.protocolVersion || protocolVersion;
          reply(msg.id, {
            protocolVersion,
            capabilities: { tools: {} },
            serverInfo: { name: 'oro-mcp-gateway', version: '0.1.0' },
          });
          break;
        }
        case 'tools/list': {
          await ensureBackendsInitialized();
          reply(msg.id, { tools: aggregatedTools() });
          break;
        }
        case 'tools/call': {
          await ensureBackendsInitialized();
          const target = resolveBackendAndTool(msg.params?.name || '');
          if (!target) {
            replyError(msg.id, -32602, `tool desconocida o mal formada: "${msg.params?.name}" (se espera "<backend>__<tool>")`);
            break;
          }
          const result = await target.backend.callTool(target.realName, msg.params?.arguments);
          reply(msg.id, result);
          break;
        }
        case 'ping': {
          reply(msg.id, {});
          break;
        }
        default: {
          // resources/list, prompts/list, etc.: ningún backend actual los usa.
          // Responder con listas vacías en vez de error evita que el cliente
          // trate al gateway como roto por una capability que no hace falta.
          if (msg.method === 'resources/list') reply(msg.id, { resources: [] });
          else if (msg.method === 'prompts/list') reply(msg.id, { prompts: [] });
          else replyError(msg.id, -32601, `método no soportado por el gateway: "${msg.method}"`);
        }
      }
    } catch (err) {
      replyError(msg.id, -32000, err.message || String(err));
    }
  }

  async function shutdown() {
    // Esperar los mensajes todavía en vuelo (ver el comentario sobre el
    // tracking de `inFlight` más arriba) antes de matar los backends —
    // si no, un `tools/call` que llegó en la última línea del stream nunca
    // recibe respuesta.
    await Promise.allSettled([...inFlight]);
    for (const b of backends.values()) {
      if (b.child && !b.child.killed) b.child.kill();
    }
    process.exit(0);
  }
  // stdin cerrado (el cliente MCP terminó, o en el test manual con `< archivo`)
  // es la señal real de fin de sesión: sin esto, los backends spawneados
  // (ej. el proceso de `npx` del server de memoria) quedan corriendo huérfanos.
  rl.on('close', shutdown);
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main().catch((err) => {
  log('fatal:', err);
  process.exit(1);
});
