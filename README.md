# Doctiling — Self-host

Run [Doctiling](https://doctiling.app) entirely on your own machine: your documents, your database, and (optionally) your own local AI. Nothing leaves your laptop.

*[Versión en español más abajo.](#doctiling--instalación-en-español)*

---

## Requirements

- **macOS** 12+ (Apple Silicon or Intel), **Windows** 10/11, or **Linux** (x64/arm64)
- ~500 MB of disk (app + embedded Node runtime + your data)
- **Optional, for local AI**: [LM Studio](https://lmstudio.ai) or [Ollama](https://ollama.com) — see [Local AI](#local-ai)

No Node, Docker, or account required. The installer downloads everything it needs. Managed/corporate Windows machines work too: if policy denies scheduled tasks, the installer falls back to a per-user Run key automatically.

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

### Windows with Scoop (recommended on Windows)

```powershell
scoop bucket add doctiling https://github.com/doctiling/scoop-bucket
scoop install doctiling
```

### Windows (direct PowerShell)

```powershell
irm https://raw.githubusercontent.com/doctiling/releases/main/install.ps1 | iex
```

## What the installer does

1. Downloads the app (Scoop also installs a pinned Node LTS as a dependency).
2. Generates every secret for you in the `.env` — auth secret, encryption key, and web-push keys. You never touch a key to get started.
3. Creates a local SQLite database — full-text and vector search included, no external database.
4. Registers autostart and opens **http://127.0.0.1:3000**.

The server listens **only on 127.0.0.1** — it is never reachable from your network.

### Where things live

| | macOS / Linux | Windows (Scoop) | Windows (direct script) |
|---|---|---|---|
| App code | `~/.doctiling/current` | `~\scoop\apps\doctiling\current` | `%LOCALAPPDATA%\Doctiling\current` |
| `.env`, database, logs | `~/.doctiling/` | `%USERPROFILE%\.doctiling\` | `%LOCALAPPDATA%\Doctiling\` |
| Autostart | launchd (macOS) | "Doctiling" scheduled task, or a per-user Run key on managed machines | same |

## First steps

1. Open **http://127.0.0.1:3000** and click **Enter your studio** — no account, no email; this install is single-user.
2. Install it as a desktop app when your browser offers it (address-bar install icon).
3. Create a knowledge base and upload a document. To ask the AI about it, set up [Local AI](#local-ai) below (or add a cloud key).

## Local AI

The default configuration points at an OpenAI-compatible local server on `http://127.0.0.1:1234/v1`:

- **LM Studio**: load a chat model (e.g. Llama 3.1 8B Instruct) and an embedding model (`nomic-embed-text-v1.5`), then enable the local server (default port 1234).
- **Ollama**: `ollama pull llama3.1 && ollama pull nomic-embed-text`, then edit your `.env` → `LLM_BASE_URL=http://127.0.0.1:11434/v1` and set `LLM_MODEL`/`OPENAI_EMBED_MODEL` to your model names.

The embedding model must emit **768-dimension** vectors (nomic-embed-text does).

Prefer cloud AI? Add any of `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, or `OPENAI_API_KEY` to your `.env`, switch `LLM_PROVIDER`/`EMBEDDING_PROVIDER` accordingly, and restart. You can also change providers from the in-app **Configure AI** dialog.

## Day-2 operations

**macOS / Linux** — the bundled CLI:

```sh
~/.doctiling/bin/doctiling status    # is it running?
~/.doctiling/bin/doctiling stop
~/.doctiling/bin/doctiling start
~/.doctiling/bin/doctiling logs      # tail the server log
~/.doctiling/bin/doctiling update    # upgrade to the latest release
```

(Homebrew: `brew upgrade doctiling`.)

**Windows (Scoop)** — there is no `doctiling` CLI; use these instead:

```powershell
# Update (then restart the process — the old one keeps port 3000 otherwise)
scoop update doctiling
Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
Start-Process powershell -WindowStyle Hidden -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$env:USERPROFILE\.doctiling\bin\doctiling-run.ps1`""

# Logs
Get-Content "$env:USERPROFILE\.doctiling\logs\doctiling.log" -Tail 40

# Stop / start
Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
Start-Process powershell -WindowStyle Hidden -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$env:USERPROFILE\.doctiling\bin\doctiling-run.ps1`""
```

**Backup**: copy the data directory (`~/.doctiling/data/` — Windows Scoop: `%USERPROFILE%\.doctiling\data\`): the SQLite file plus its WAL sidecars are your entire workspace.

**Uninstall**: stop the app, then delete the data directory and the autostart entry (`~/Library/LaunchAgents/app.doctiling.plist` on macOS; on Windows the "Doctiling" task in Task Scheduler **or** the "Doctiling" value under `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run`).

## Troubleshooting

| Symptom | Check |
|---|---|
| Nothing on port 3000 | Tail the log (see Day-2 above) — the last lines name the failure |
| Windows: "Acceso denegado / PermissionDenied" during install | Fixed since v0.7.2 — the installer falls back to a per-user Run key. Update and re-run. |
| Windows: every page answers **500** | Fixed since v0.7.3 (`scoop update doctiling`, then restart per Day-2). If it persists, tail the log and check the paths in the stack: they must say the NEW version — if they say an old one, the old process still owns port 3000. |
| The fix I installed "doesn't work" | Same as above: after any update, kill the process on port 3000 and start the runner again. A running server keeps the old code in memory. |
| AI replies with a connection error | Is LM Studio/Ollama serving on the URL in `.env`? Test: `curl http://127.0.0.1:1234/v1/models` |
| Documents upload but AI can't find them | Embedding model missing or not 768-dim — check the log for `embedding` errors |
| Port 3000 taken by something else | Set `PORT=` in your `.env` and restart |

Every release lists what changed and how to update: [Releases](https://github.com/doctiling/releases/releases).

---

# Doctiling — instalación (en español)

Ejecuta Doctiling completamente en tu máquina: tus documentos, tu base de datos y, si quieres, tu propia IA local. Nada sale de tu laptop. Funciona también en equipos Windows administrados por tu empresa: si la política niega las tareas programadas, el instalador usa la clave Run de tu usuario automáticamente.

## Instalar

**macOS / Linux:**
```sh
curl -fsSL https://raw.githubusercontent.com/doctiling/releases/main/install.sh | sh
```

**macOS con Homebrew:** `brew tap doctiling/tap && brew trust doctiling/tap && brew install doctiling && brew services start doctiling`

**Windows con Scoop (recomendado):**
```powershell
scoop bucket add doctiling https://github.com/doctiling/scoop-bucket
scoop install doctiling
```

**Windows (PowerShell directo):**
```powershell
irm https://raw.githubusercontent.com/doctiling/releases/main/install.ps1 | iex
```

El instalador descarga la app, **genera todas las llaves por ti**, crea la base de datos local y registra el arranque automático. El servidor solo escucha en `127.0.0.1` (nunca queda expuesto a tu red).

## Dónde queda cada cosa

| | macOS / Linux | Windows (Scoop) | Windows (script directo) |
|---|---|---|---|
| App | `~/.doctiling/current` | `~\scoop\apps\doctiling\current` | `%LOCALAPPDATA%\Doctiling\current` |
| `.env`, datos y logs | `~/.doctiling/` | `%USERPROFILE%\.doctiling\` | `%LOCALAPPDATA%\Doctiling\` |

## Primeros pasos

1. Abre **http://127.0.0.1:3000** y pulsa **Entra a tu estudio** — sin cuenta ni correo.
2. Instálalo como app de escritorio desde el navegador.
3. Crea una base de conocimiento y sube un documento. Para IA local: instala [LM Studio](https://lmstudio.ai) (modelo de chat + embeddings `nomic-embed-text-v1.5`, servidor en el puerto 1234) u [Ollama](https://ollama.com) (edita `LLM_BASE_URL` en tu `.env` a `http://127.0.0.1:11434/v1`). ¿Prefieres IA en la nube? Agrega tu llave (`ANTHROPIC_API_KEY`, `GEMINI_API_KEY` u `OPENAI_API_KEY`) al mismo archivo.

## Operación diaria

- **macOS/Linux**: `~/.doctiling/bin/doctiling start|stop|status|update|logs`. Homebrew: `brew upgrade doctiling`.
- **Windows (Scoop)** — no hay CLI; los comandos equivalentes:

```powershell
# Actualizar (y SIEMPRE reiniciar el proceso: el viejo se queda con el puerto)
scoop update doctiling
Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
Start-Process powershell -WindowStyle Hidden -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$env:USERPROFILE\.doctiling\bin\doctiling-run.ps1`""

# Ver el log (aquí aparece la causa de cualquier fallo)
Get-Content "$env:USERPROFILE\.doctiling\logs\doctiling.log" -Tail 40
```

**Backup**: copia la carpeta de datos (`~/.doctiling/data/`; en Windows Scoop `%USERPROFILE%\.doctiling\data\`) — ahí vive todo tu espacio de trabajo.

## Si algo falla

1. Mira el log (comando arriba): las últimas líneas nombran la causa.
2. **Después de actualizar, reinicia el proceso** — un servidor corriendo mantiene el código viejo en memoria y "el fix no funciona" hasta que lo matas y arrancas de nuevo.
3. Si la IA no responde: verifica que LM Studio/Ollama estén sirviendo en la URL del `.env` (`curl http://127.0.0.1:1234/v1/models`).
4. Cada release explica qué cambió y cómo actualizar: [Releases](https://github.com/doctiling/releases/releases).
