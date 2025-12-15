#!/bin/bash
# Redmine Theme Development Helper Script für Podman

set -e

CONTAINER_DB="redmine-db"
CONTAINER_REDMINE="redmine-dev"
NETWORK="redmine-net"
THEME_PATH="/Users/sim/.claude-worktrees/redmine-theme-flat/great-northcutt"

case "$1" in
  start)
    echo "🚀 Starte Redmine Entwicklungsumgebung..."

    # Prüfe ob Podman Machine läuft
    if ! podman machine list | grep -q "Currently running"; then
      echo "⚠️  Podman Machine wird gestartet..."
      podman machine start
      sleep 5
    fi

    # Netzwerk erstellen falls nicht vorhanden
    podman network exists $NETWORK 2>/dev/null || podman network create $NETWORK

    # Datenbank starten
    if ! podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_DB}$"; then
      echo "📦 Erstelle PostgreSQL Container..."
      podman run -d --name $CONTAINER_DB \
        --network $NETWORK \
        -e POSTGRES_PASSWORD=redmine \
        -e POSTGRES_DB=redmine \
        postgres:13
    else
      echo "▶️  Starte PostgreSQL Container..."
      podman start $CONTAINER_DB 2>/dev/null || true
    fi

    # Redmine starten
    if ! podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_REDMINE}$"; then
      echo "📦 Erstelle Redmine Container..."
      podman run -d --name $CONTAINER_REDMINE \
        --network $NETWORK \
        -p 3000:3000 \
        -e REDMINE_DB_POSTGRES=$CONTAINER_DB \
        -e REDMINE_DB_DATABASE=redmine \
        -e REDMINE_DB_PASSWORD=redmine \
        -v ${THEME_PATH}:/usr/src/redmine/public/themes/flat:Z \
        redmine:5.1

      echo "⏳ Warte auf Redmine-Start (kann 30-60 Sekunden dauern)..."
      sleep 10

      # Node.js installieren für Sass-Kompilierung
      echo "📦 Installiere Node.js für Sass..."
      podman exec -u root $CONTAINER_REDMINE bash -c "
        apt-get update -qq &&
        apt-get install -y -qq curl &&
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &&
        apt-get install -y -qq nodejs
      " > /dev/null 2>&1

      # npm-Dependencies installieren
      echo "📦 Installiere npm-Dependencies..."
      podman exec -w /usr/src/redmine/public/themes/flat $CONTAINER_REDMINE npm install > /dev/null 2>&1

      echo "🎨 Kompiliere Sass..."
      podman exec -w /usr/src/redmine/public/themes/flat $CONTAINER_REDMINE npm run compile > /dev/null 2>&1

      # Admin-Passwort setzen
      echo "🔑 Setze Admin-Passwort..."
      podman exec $CONTAINER_REDMINE bundle exec rails runner -e production "
        user = User.find_by(login: 'admin')
        if user
          user.password = 'admin123'
          user.password_confirmation = 'admin123'
          user.must_change_passwd = false
          user.save!
        end
      " > /dev/null 2>&1
    else
      echo "▶️  Starte Redmine Container..."
      podman start $CONTAINER_REDMINE
    fi

    echo ""
    echo "✅ Entwicklungsumgebung läuft!"
    echo ""
    echo "📍 Redmine URL: http://localhost:3000"
    echo "👤 Login: admin / admin123"
    echo ""
    echo "🎨 Theme aktivieren:"
    echo "   Administration → Einstellungen → Anzeige → Theme → 'flat'"
    echo ""
    echo "Nützliche Befehle:"
    echo "  ./dev.sh compile  - Sass kompilieren"
    echo "  ./dev.sh watch    - Sass Watch-Modus"
    echo "  ./dev.sh logs     - Logs ansehen"
    echo "  ./dev.sh restart  - Redmine neu starten"
    echo "  ./dev.sh stop     - Umgebung stoppen"
    ;;

  stop)
    echo "🛑 Stoppe Redmine Entwicklungsumgebung..."
    podman stop $CONTAINER_REDMINE $CONTAINER_DB 2>/dev/null || true
    echo "✅ Gestoppt"
    ;;

  restart)
    echo "🔄 Starte Redmine neu..."
    podman restart $CONTAINER_REDMINE
    echo "✅ Neustart abgeschlossen"
    echo "📍 http://localhost:3000"
    ;;

  logs)
    echo "📋 Redmine Logs (Ctrl+C zum Beenden):"
    echo "----------------------------------------"
    podman logs -f $CONTAINER_REDMINE
    ;;

  logs-tail)
    echo "📋 Letzte 50 Log-Zeilen:"
    echo "----------------------------------------"
    podman logs --tail 50 $CONTAINER_REDMINE
    ;;

  compile)
    echo "🎨 Kompiliere Sass..."
    podman exec -w /usr/src/redmine/public/themes/flat $CONTAINER_REDMINE npm run compile
    echo "✅ Sass kompiliert"
    ;;

  watch)
    echo "👀 Sass Watch-Modus (Ctrl+C zum Beenden)..."
    echo "Änderungen in sass/ werden automatisch kompiliert"
    echo "----------------------------------------"
    podman exec -w /usr/src/redmine/public/themes/flat $CONTAINER_REDMINE npm run watch
    ;;

  console)
    echo "🔧 Öffne Rails Console..."
    podman exec -it $CONTAINER_REDMINE rails console
    ;;

  shell)
    echo "🐚 Öffne Container Shell..."
    podman exec -it $CONTAINER_REDMINE bash
    ;;

  status)
    echo "📊 Container Status:"
    echo "----------------------------------------"
    podman ps -a --filter "name=redmine"
    echo ""
    echo "📍 Redmine URL: http://localhost:3000"
    ;;

  clean)
    echo "🧹 Lösche alle Container und Volumes..."
    read -p "Bist du sicher? Alle Daten gehen verloren! (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      podman stop $CONTAINER_REDMINE $CONTAINER_DB 2>/dev/null || true
      podman rm $CONTAINER_REDMINE $CONTAINER_DB 2>/dev/null || true
      podman network rm $NETWORK 2>/dev/null || true
      echo "✅ Aufgeräumt"
    else
      echo "❌ Abgebrochen"
    fi
    ;;

  db)
    echo "🗄️  Verbinde zu PostgreSQL..."
    podman exec -it $CONTAINER_DB psql -U postgres -d redmine
    ;;

  *)
    echo "Redmine Theme Development Helper"
    echo ""
    echo "Verwendung: ./dev.sh [command]"
    echo ""
    echo "Befehle:"
    echo "  start       - Starte Entwicklungsumgebung"
    echo "  stop        - Stoppe Entwicklungsumgebung"
    echo "  restart     - Starte Redmine neu"
    echo "  compile     - Kompiliere Sass"
    echo "  watch       - Sass Watch-Modus (Auto-Kompilierung)"
    echo "  logs        - Zeige Live-Logs (Ctrl+C zum Beenden)"
    echo "  logs-tail   - Zeige letzte 50 Log-Zeilen"
    echo "  console     - Öffne Rails Console"
    echo "  shell       - Öffne Container Shell (bash)"
    echo "  db          - Öffne PostgreSQL Console"
    echo "  status      - Zeige Container-Status"
    echo "  clean       - Lösche alle Container & Volumes (VORSICHT!)"
    echo ""
    echo "Beispiel-Workflow:"
    echo "  1. ./dev.sh start     # Umgebung starten"
    echo "  2. ./dev.sh watch     # Sass Watch-Modus in neuem Terminal"
    echo "  3. Theme bearbeiten (sass/)"
    echo "  4. Browser testen: http://localhost:3000"
    echo "  5. ./dev.sh stop      # Fertig für heute"
    ;;
esac
