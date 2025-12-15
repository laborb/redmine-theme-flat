# Entwicklungsumgebung Setup

Dieses Dokument beschreibt das lokale Development-Setup für das Redmine Flat Theme mit Podman.

## Voraussetzungen

- macOS
- Podman Desktop installiert
- Podman Machine gestartet

## Schnellstart

```bash
# Entwicklungsumgebung starten
./dev.sh start

# Browser öffnen: http://localhost:3000
# Login: admin / admin123
```

## Entwicklungs-Workflow

### 1. Umgebung starten
```bash
./dev.sh start
```

### 2. Theme aktivieren
1. Browser: http://localhost:3000
2. Login: `admin` / `admin123`
3. Administration → Einstellungen → Anzeige → Theme
4. Wähle "flat" aus der Dropdown-Liste und speichere

### 3. Theme bearbeiten & testen
```bash
# In einem Terminal: Watch-Modus starten
./dev.sh watch

# In VS Code/Editor: Sass-Dateien bearbeiten (sass/)
# Änderungen werden automatisch kompiliert

# Im Browser testen
# Browser neu laden: Cmd+Shift+R (Hard-Reload)
```

### 4. Manuelle Sass-Kompilierung
```bash
# Einmalig kompilieren
./dev.sh compile
```

### 5. Committen & Pushen
```bash
git add sass/ stylesheets/
git commit -m "Deine Änderung"
git push
```

## Helper-Script Befehle

```bash
./dev.sh start       # Umgebung starten
./dev.sh stop        # Umgebung stoppen
./dev.sh restart     # Redmine neu starten
./dev.sh compile     # Sass kompilieren
./dev.sh watch       # Sass Watch-Modus (Auto-Kompilierung)
./dev.sh logs        # Live-Logs ansehen
./dev.sh logs-tail   # Letzte 50 Log-Zeilen
./dev.sh console     # Rails Console öffnen
./dev.sh shell       # Container Shell öffnen
./dev.sh db          # PostgreSQL Console öffnen
./dev.sh status      # Container-Status anzeigen
./dev.sh clean       # Alles löschen & neu anfangen
```

## Zugangsdaten

### Redmine (lokal)
- URL: http://localhost:3000
- Benutzer: `admin`
- Passwort: `admin123`

### PostgreSQL (lokal)
- Host: `localhost:5432` (oder `redmine-db` innerhalb des Netzwerks)
- Datenbank: `redmine`
- Benutzer: `postgres`
- Passwort: `redmine`

## Theme-Struktur

```
.
├── sass/                  # Sass Source-Dateien
│   ├── application.scss   # Haupt-Sass-Datei
│   └── partials/         # Sass-Partials
├── stylesheets/          # Kompilierte CSS-Dateien
│   └── application.css   # Kompiliertes CSS (wird von Redmine geladen)
├── images/               # Theme-Bilder
├── javascripts/          # JavaScript-Dateien
├── fonts/                # Theme-Schriftarten
├── package.json          # npm Dependencies
└── dev.sh               # Development Helper Script
```

## Debugging

### Logs ansehen
```bash
# Live-Logs
./dev.sh logs

# Letzte Zeilen
./dev.sh logs-tail
```

### Rails Console
```bash
./dev.sh console

# Im Console:
irb> Setting.ui_theme
irb> User.current
```

### Container Shell
```bash
./dev.sh shell

# Im Container:
cd /usr/src/redmine/public/themes/flat
ls -la
```

### Sass Syntax Check
```bash
# In lokalem Terminal (wenn sass installiert)
npx sass --no-source-map --check sass/application.scss

# Im Container
./dev.sh shell
cd /usr/src/redmine/public/themes/flat
npm run compile
```

## Troubleshooting

### Podman startet nicht
```bash
# Podman Machine Status prüfen
podman machine list

# Podman Machine starten
podman machine start

# Bei Problemen: SSH Known Hosts aufräumen
ssh-keygen -R "[127.0.0.1]:51698"
podman machine stop
podman machine start
```

### Container laufen nicht
```bash
# Status prüfen
./dev.sh status

# Logs prüfen
./dev.sh logs-tail

# Komplett neu aufsetzen
./dev.sh clean
./dev.sh start
```

### Theme wird nicht angezeigt
```bash
# Sass neu kompilieren
./dev.sh compile

# Redmine neu starten
./dev.sh restart

# Browser-Cache leeren (Cmd+Shift+R)

# Theme-Aktivierung prüfen
# Administration → Einstellungen → Anzeige → Theme = "flat"
```

### Sass-Kompilierung schlägt fehl
```bash
# npm-Dependencies neu installieren
./dev.sh shell
cd /usr/src/redmine/public/themes/flat
npm install
exit

# Dann neu kompilieren
./dev.sh compile
```

### Port 3000 bereits belegt
```bash
# Prozess finden
lsof -i :3000

# Container mit anderem Port starten (dev.sh anpassen):
# -p 3001:3000
```

### Theme-Änderungen werden nicht geladen
```bash
# 1. Sass kompilieren
./dev.sh compile

# 2. Browser-Cache leeren
# Cmd+Shift+R (macOS) oder Strg+Shift+R (Windows/Linux)

# 3. Falls immer noch nicht: Redmine neu starten
./dev.sh restart
```

## Architektur

```
┌─────────────────────────────────────────┐
│ macOS (Host)                            │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ Podman Machine (VM)             │   │
│  │                                 │   │
│  │  ┌──────────┐    ┌───────────┐ │   │
│  │  │ Postgres │◄───│  Redmine  │ │   │
│  │  │   :5432  │    │   :3000   │ │   │
│  │  └──────────┘    └─────▲─────┘ │   │
│  │                        │       │   │
│  │                        │       │   │
│  └────────────────────────┼───────┘   │
│                           │           │
│  ┌────────────────────────┼───────┐   │
│  │ Theme-Verzeichnis (Volume)    │   │
│  │ /Users/sim/.claude-worktrees/ │   │
│  └───────────────────────────────┘   │
└─────────────────────────────────────────┘
              │
              │ Port Forward
              ▼
        http://localhost:3000
```

## Produktions-Deployment

Dieses Setup ist für die **Entwicklung** konzipiert. Für Produktion:

1. **Sass kompilieren:**
   ```bash
   ./dev.sh compile
   ```

2. **Nur diese Dateien deployen:**
   - `stylesheets/application.css` (kompiliertes CSS)
   - `images/`
   - `javascripts/`
   - `fonts/`

3. **Nicht deployen:**
   - `sass/` (Quellen)
   - `node_modules/`
   - `package.json`, `package-lock.json`
   - Entwicklungs-Dateien (`dev.sh`, `DEVELOPMENT.md`)

## Weitere Ressourcen

- [Redmine Theme Tutorial](https://www.redmine.org/projects/redmine/wiki/Theme_Tutorial)
- [Sass Documentation](https://sass-lang.com/documentation)
- [Podman Documentation](https://docs.podman.io/)
