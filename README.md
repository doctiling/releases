# Doctiling — Self-host

Run [Doctiling](https://doctiling.app) entirely on your own machine: your documents, your database, and (optionally) your own local AI. Nothing leaves your laptop.

*[Versión en español más abajo.](#doctiling--instalación-en-español)*

---

## Requirements

- **macOS** 12+ (Apple Silicon or Intel), **Windows** 10/11, or **Linux** (x64/arm64)
- ~500 MB of disk (app + embedded Node runtime + your data)
- **Optional, for local AI**: [LM Studio](https://lmstudio.ai) or [Ollama](https://ollama.com) — see [Local AI](#local-ai)

No Node, Docker, or account required. The installer downloads everything it needs.

## Install

### macOS / Linux (one command)

```sh
curl -fsSL https://raw.githubusercontent.com/doctiling/releases/main/install.sh | sh
```

### macOS with Homebrew

```sh
brew tap doctiling/tap
brew trust doctiling/tap        # Homebrew requires trusting third-party taps
brew install doctiling
brew services start doctiling   # start now + at login
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/doctiling/releases/main/install.ps1 | iex
```

### Windows with Scoop

```powershell
scoop bucket add doctiling https://github.com/doctiling/scoop-bucket
scoop install doctiling
```

## What the installer does

1. Downloads the latest release and a pinned Node 20 runtime into `~/.doctiling` (Windows: `%LOCALAPPDATA%\Doctiling`).
2. Generates every secret for you in `~/.doctiling/.env` — auth secret, encryption key, and web-push keys. You never touch a key to get started.
3. Creates a local SQLite database (`~/.doctiling/data/app.db`) — full-text and vector search included, no external database.
4. Registers autostart (launchd on macOS, a logon task on Windows) and opens **http://127.0.0.1:3000**.

The server listens **only on 127.0.0.1** — it is never reachable from your network.

## First steps

1. Open **http://127.0.0.1:3000** and click **Enter your studio** — no account, no email; this install is single-user.
2. Install it as a desktop app when your browser offers it (address-bar install icon).
3. Create a notebook and upload a document. To ask the AI about it, set up [Local AI](#local-ai) below (or add a cloud key).

## Local AI

The default configuration points at an OpenAI-compatible local server on `http://127.0.0.1:1234/v1`:

- **LM Studio**: load a chat model (e.g. Llama 3.1 8B Instruct) and an embedding model (`nomic-embed-text-v1.5`), then enable the local server (default port 1234).
- **Ollama**: `ollama pull llama3.1 && ollama pull nomic-embed-text`, then edit `~/.doctiling/.env` → `LLM_BASE_URL=http://127.0.0.1:11434/v1` and set `LLM_MODEL`/`OPENAI_EMBED_MODEL` to your model names.

The embedding model must emit **768-dimension** vectors (nomic-embed-text does).

Prefer cloud AI? Add any of `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, or `OPENAI_API_KEY` to `~/.doctiling/.env`, switch `LLM_PROVIDER`/`EMBEDDING_PROVIDER` accordingly, and restart. You can also change providers from the in-app **Configure AI** dialog.

## Day-2 operations

```sh
~/.doctiling/bin/doctiling status    # is it running?
~/.doctiling/bin/doctiling stop
~/.doctiling/bin/doctiling start
~/.doctiling/bin/doctiling logs      # tail the server log
~/.doctiling/bin/doctiling update    # upgrade to the latest release
```

(Homebrew: `brew upgrade doctiling` · Scoop: `scoop update doctiling`.)

**Backup**: copy `~/.doctiling/data/` (the SQLite file plus its WAL sidecars) — that's your entire workspace.

**Uninstall**: stop the app, then delete `~/.doctiling` and the autostart entry (`~/Library/LaunchAgents/app.doctiling.plist` on macOS; the "Doctiling" task in Task Scheduler on Windows).

## Troubleshooting

| Symptom | Check |
|---|---|
| Nothing on port 3000 | `~/.doctiling/bin/doctiling logs` — the last lines name the failure |
| AI replies with a connection error | Is LM Studio/Ollama serving on the URL in `.env`? Test: `curl http://127.0.0.1:1234/v1/models` |
| Documents upload but AI can't find them | Embedding model missing or not 768-dim — check the log for `embedding` errors |
| Port 3000 taken | Set `PORT=` in `~/.doctiling/.env` and restart |

---

# Doctiling — instalación (en español)

Ejecuta Doctiling completamente en tu máquina: tus documentos, tu base de datos y, si quieres, tu propia IA local. Nada sale de tu laptop.

## Instalar

**macOS / Linux:**
```sh
curl -fsSL https://raw.githubusercontent.com/doctiling/releases/main/install.sh | sh
```

**macOS con Homebrew:** `brew tap doctiling/tap && brew trust doctiling/tap && brew install doctiling && brew services start doctiling`

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/doctiling/releases/main/install.ps1 | iex
```

**Windows con Scoop:** `scoop bucket add doctiling https://github.com/doctiling/scoop-bucket && scoop install doctiling`

El instalador descarga la app y un Node embebido en `~/.doctiling`, **genera todas las llaves por ti**, crea la base de datos local y registra el arranque automático. El servidor solo escucha en `127.0.0.1` (nunca queda expuesto a tu red).

## Primeros pasos

1. Abre **http://127.0.0.1:3000** y pulsa **Entra a tu estudio** — sin cuenta ni correo.
2. Instálalo como app de escritorio desde el navegador.
3. Para IA local: instala [LM Studio](https://lmstudio.ai) (modelo de chat + modelo de embeddings `nomic-embed-text-v1.5`, servidor en el puerto 1234) u [Ollama](https://ollama.com) (edita `LLM_BASE_URL` en `~/.doctiling/.env` a `http://127.0.0.1:11434/v1`). ¿Prefieres IA en la nube? Agrega tu llave (`ANTHROPIC_API_KEY`, `GEMINI_API_KEY` u `OPENAI_API_KEY`) al mismo archivo.

## Operación

`~/.doctiling/bin/doctiling start|stop|status|update|logs` · Backup: copia `~/.doctiling/data/`. Los detalles y solución de problemas están en la sección en inglés arriba.
