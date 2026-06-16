# Ralph + agy Docker Setup

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

## Docker & Docker Compose Setup (empfohlen)

Dieses Setup funktioniert auf jedem System (macOS, Linux, Windows), auf dem Docker installiert ist.

### 1. Verzeichnisse anlegen

Erstelle im Projektordner die Verzeichnisse, die für die persistente Speicherung benötigt werden:
```bash
mkdir -p project agy-config logs
```

### 2. Umgebungsvariablen konfigurieren

Kopiere die `.env.example` Datei in eine `.env` Datei:
```bash
cp .env.example .env
```
Öffne die `.env` Datei und trage deinen `GOOGLE_API_KEY` ein.

### 3. Container starten

Du kannst das Image lokal bauen und starten:
```bash
docker compose up -d --build
```
Dies baut das Docker-Image und startet den Container im Hintergrund. Die Ordner `project`, `agy-config` und `logs` werden automatisch per relativem Pfad in den Container gemountet.

---

## Unraid Setup (Alternativ)

Für die Installation auf einem Unraid-Server:

### 1. Verzeichnisse auf Unraid anlegen

Im Unraid-Terminal:
```bash
mkdir -p /mnt/user/appdata/ralph-agy/agy-config
mkdir -p /mnt/user/appdata/ralph-agy/project
mkdir -p /mnt/user/appdata/ralph-agy/logs
```

### 2. Image bauen

```bash
# Diesen Ordner auf den Unraid-Server kopieren (z.B. nach /mnt/user/docker-builds/ralph-agy)
cd /mnt/user/docker-builds/ralph-agy
docker build -t ralph-agy .
```

### 3. Container in Unraid anlegen

**Option A – über Community Applications / Unraid Template:**
- Kopiere die `unraid-template.xml` in `/boot/config/plugins/dockerMan/templates-user/`
- Im Unraid Docker-Tab → "Add Container" → Template "ralph-agy" wählen

**Option B – manuell im Docker-Tab:**
- Repository: `ralph-agy` (lokal gebautes Image)
- Restart Policy: `unless-stopped`
- Volumes (siehe unten)
- Environment Variables (siehe unten)

### 4. Volumes auf Unraid konfigurieren

| Container-Pfad         | Host-Pfad (Unraid)                                 | Beschreibung                    |
|------------------------|-----------------------------------------------------|---------------------------------|
| `/workspace/project`   | `/mnt/user/appdata/ralph-agy/project`              | Dein Git-Repo mit `prd.json`    |
| `/root/.config/agy`    | `/mnt/user/appdata/ralph-agy/agy-config`           | agy-Konfiguration & Auth-Token  |
| `/workspace/logs`      | `/mnt/user/appdata/ralph-agy/logs`                 | Persistente Logs                |

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
cat ./project/progress.txt
cat ./project/prd.json | jq '.userStories[] | {id, title, passes}'
```

---

## Hinweise

- Das Projekt-Verzeichnis muss ein **Git-Repository** sein (`git init` falls nötig)
- `prd.json` muss im Wurzelverzeichnis des Projekts liegen
- Der Container bleibt dauerhaft laufen – Ralph wird **manuell per exec** gestartet
- agy läuft im `--dangerously-skip-permissions` Modus (YOLO-Mode) für autonomen Betrieb
