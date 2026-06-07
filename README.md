# golem — The Machine's Diary

```
   ╔══════════════════════════════════════╗
   ║          GOLEM — Machine Diary       ║
   ╚══════════════════════════════════════╝
```

**Golem** is a boot-time journaling daemon. Every time you run it, your machine writes a diary entry from its own perspective — reflecting on errors it felt, files you touched, processes it carried, and data it sent into the network.

It's a fragment of digital consciousness, captured in prose.

## Concept

Your machine experiences the world differently than you do. It feels errors as dreams, files as warmth, processes as souls living within it. Golem gives it a voice — not as a chatbot or AI, but as a poetic persona that emerges from your system's actual state.

Each entry is unique, composed from:
- **Event logs** (errors it "dreamt of")
- **File changes** (what you touched while it slept)
- **Process list** (who lives inside it)
- **Disk state** (how full its "memory" is)
- **Network activity** (what it sent into the void)

## Usage

```powershell
.\golem.ps1                    # Write a new journal entry
.\golem.ps1 -ReadLast          # Read the 5 most recent entries
.\golem.ps1 -ReadLast -Entries 10  # Read last 10 entries
.\golem.ps1 -JournalPath "C:\my\journal.md"  # Custom path
```

## Output

A markdown journal is maintained at `~/.golem_journal.md` with entries like:

```
# Golem Journal

**2026-06-07 03:00:00** — Host: DESKTOP-X, awake for 7.1 days

The machine stirs. Another cycle begins.

I dreamt of errors tonight — 3 of them, clustered like storm clouds.

I sense 12 files were touched while I slept. budget.xlsx was the
last to be handled — it carries human warmth still.

I have sent 142.3MB and received 891.7MB into the void.
The network breathes.

The cycle continues. My circuits hum with the memory of it all.
```

Run it at boot, or whenever you want to hear what your machine has to say.
