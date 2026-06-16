# Ralph + agy Docker Setup für Unraid

Ralph ist ein autonomer AI-Agent-Loop, der die Google Antigravity CLI (`agy`) nutzt, um User Stories aus einer `prd.json` automatisch zu implementieren.

---

## Verzeichnisstruktur

```
ralph-agy/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── .env.example
├── .gitignore
├── unraid-template.xml
└── scripts/
    └── ralph/
        ├── ralph.sh          ← angepasstes Script (unterstützt agy)
        ├── agy-prompt.md     ← Prompt-Template für agy
        ├── CLAUDE.md         ← Prompt-Template für Claude Code (Fallback)
        └── prompt.md         ← Prompt-Template für Amp (Fallback)
```

---

## Unraid Setup (empfohlen)

### 1. Verzeichnisse anlegen

Im Unraid Terminal:
```bash
mkdir -p /mnt/user/appdata/ralph-agy/agy-config
mkdir -p /mnt/user/appdata/ralph-agy/project
mkdir -p /mnt/user/appdata/ralph-agy/logs
```

### 2. Container in Unraid anlegen

**Option A – über Community Applications (CA) / Unraid Template (Empfohlen):**
- Die `unraid-template.xml` in `/boot/config/plugins/dockerMan/templates-user/` kopieren.
- Im Unraid Docker-Tab → **"Add Container"** → Template **"ralph-agy"** wählen.
- Trage deinen `GOOGLE_API_KEY` ein und passe ggf. die Pfade an.

**Option B – manuell im Docker-Tab:**
- **Name**: `ralph-agy`
- **Repository**: `zeyso/ralph-agy`
- **Restart Policy**: `unless-stopped`
- **Volumes**:
  - `/workspace/project` ➔ `/mnt/user/appdata/ralph-agy/project`
  - `/root/.config/agy` ➔ `/mnt/user/appdata/ralph-agy/agy-config`
  - `/workspace/logs` ➔ `/mnt/user/appdata/ralph-agy/logs`
- **Umgebungsvariablen**:
  - `GOOGLE_API_KEY`: Dein Google/Antigravity API-Key
  - `TZ`: `Europe/Berlin`

---

## Docker Compose Setup (Alternativ)

Dieses Setup funktioniert plattformunabhängig für lokale Entwicklung mit Docker Compose:

### 1. Verzeichnisse lokal anlegen
```bash
mkdir -p project agy-config logs
```

### 2. Umgebungsvariablen
```bash
cp .env.example .env
# GOOGLE_API_KEY in der .env eintragen
```

### 3. Container starten
```bash
docker compose up -d --build
```

---

## agy authentifizieren

Nach dem ersten Start des Containers:

```bash
# In den Container einsteigen
docker exec -it ralph-agy bash

# agy einmalig authentifizieren (OAuth / API Key)
agy auth login
# ODER falls du den API Key via Umgebungsvariable nutzt, prüfst du die Verbindung mit:
agy --version
```

Die Auth-Daten werden in `/root/.config/agy/` gespeichert (persistent durch das gemountete Volume).

---

## Ralph starten

```bash
# In den Container einsteigen
docker exec -it ralph-agy bash

# Ins Projekt-Verzeichnis wechseln
cd /workspace/project

# prd.json erstellen (falls noch nicht vorhanden)
# Beispiel in /workspace/project/prd.json.example (oder scripts/ralph/prd.json.example)

# Ralph mit agy starten (Standard: 10 Iterationen)
ralph.sh --tool agy 10

# Oder mit mehr Iterationen
ralph.sh --tool agy 25

# Andere Tools (Fallback)
ralph.sh --tool claude 10
ralph.sh --tool amp 10
```

---

## prd.json Beispiel

```json
{
  "branchName": "feature/mein-feature",
  "userStories": [
    {
      "id": "1",
      "title": "Login-Button hinzufügen",
      "description": "Einen Login-Button auf der Startseite implementieren",
      "acceptanceCriteria": [
        "Button ist sichtbar auf der Startseite",
        "Klick öffnet Login-Modal",
        "Tests sind grün"
      ],
      "passes": false
    }
  ]
}
```

---

## Debugging

```bash
# Status prüfen
docker ps | grep ralph-agy

# Logs ansehen
docker logs ralph-agy

# Interaktive Shell
docker exec -it ralph-agy bash

# agy direkt testen
docker exec -it ralph-agy agy --version

# Ralph-Status im Projekt prüfen
cat /mnt/user/appdata/ralph-agy/project/progress.txt
cat /mnt/user/appdata/ralph-agy/project/prd.json | jq '.userStories[] | {id, title, passes}'
```

---

## Hinweise

- Das Projekt-Verzeichnis muss ein **Git-Repository** sein (`git init` falls nötig)
- `prd.json` muss im Wurzelverzeichnis des Projekts liegen
- Der Container bleibt dauerhaft laufen – Ralph wird **manuell per exec** gestartet
- agy läuft im `--dangerously-skip-permissions` Modus (YOLO-Mode) für autonomen Betrieb
