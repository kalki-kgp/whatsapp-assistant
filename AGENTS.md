## Cursor Cloud specific instructions

This is a WhatsApp MCP (Model Context Protocol) assistant with two core services:

- **Python FastAPI server** (port 3009): Main backend + embedded browser UI. Start with `source venv/bin/activate && python -m uvicorn app.main:app --host 0.0.0.0 --port 3009 --reload`
- **Node.js WhatsApp Bridge** (port 3010): Connects to WhatsApp Web via Baileys. Start with `cd bridge && npx tsx src/server.ts`

### Key caveats

- The app is designed for macOS. The `requirements.txt` includes `pyaudio` and `rumps` which are macOS-only. On Linux, install only the core deps: `pip install fastapi uvicorn openai python-dotenv httpx`. The server runs fine without pyaudio/rumps since those are only used by the optional voice assistant and menu bar modules.
- `NEBIUS_API_KEY` must be set as an environment variable (or in `.env` at the repo root). The server uses it to call the Nebius LLM API (Kimi-K2 model).
- The bridge will show a QR code on startup for WhatsApp Web authentication. Without scanning, bridge status is `qr_pending` — the server still works for conversation management and LLM chat, just not for sending/receiving WhatsApp messages.
- TypeScript compilation: `cd bridge && npx tsc --noEmit` (no lint config in the repo).
- No dedicated linter or test suite is configured in this repo.
- SQLite databases are auto-created at `/tmp/whatsapp-mcp-db/` on first server startup.
