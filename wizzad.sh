#!/bin/bash

################################################################################
# novachris_home - Wrapper Script für Ansible Playbook Ausführung
# Ermöglicht One-Click-Deployment mit Profilen
################################################################################

set -euo pipefail

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verzeichnisse
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
CONFIG_DIR="$PROJECT_ROOT/config"
INVENTORY_DIR="$PROJECT_ROOT/inventory"
LOCAL_CONFIG="$PROJECT_ROOT/.wizzad.local.yml"
PROFILE_FILE=""

################################################################################
# Funktionen
################################################################################

usage() {
  cat << EOF
${BLUE}novachris_home - Ansible Deployment Wrapper${NC}

${GREEN}Verwendung:${NC}
  $0 <profile> [options]

${GREEN}Profile:${NC}
  minimal   - Nur System-Setup, keine Apps, keine Tests
  standard  - Infrastruktur + Apps, keine Tests
  full      - Infrastruktur + Apps + Tests
  repair    - Nur Infrastruktur-Reparatur und Tests
  custom    - Interaktive Abfrage aller Parameter

${GREEN}Optionen:${NC}
  -t, --target HOST     - Ziel-Host oder Gruppe (default: proxmox_servers)
  -i, --infra           - Infrastruktur installieren
  -a, --apps            - Applikationen installieren
  -e, --test            - Tests/Maintenance ausführen
  -v, --validate        - QA-Validierung durchführen
  -d, --dry-run         - Dry-Run ohne Änderungen
  -h, --help            - Diese Hilfe anzeigen

${GREEN}Beispiele:${NC}
  $0 standard
  $0 full -t proxmox-host-01
  $0 custom
  $0 standard --dry-run

EOF
  exit 0
}

error() {
  echo -e "${RED}ERROR: $1${NC}" >&2
  exit 1
}

info() {
  echo -e "${GREEN}INFO: $1${NC}"
}

warning() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

debug() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    echo -e "${BLUE}DEBUG: $1${NC}"
  fi
}

check_prerequisites() {
  info "Prüfe Voraussetzungen..."

  # Prüfe Ansible
  if ! command -v ansible-playbook &> /dev/null; then
    error "ansible-playbook nicht gefunden. Bitte Ansible installieren."
  fi
  debug "Ansible gefunden: $(ansible-playbook --version | head -1)"

  # Prüfe Inventory
  if [[ ! -f "$INVENTORY_DIR/hosts.yml" ]]; then
    error "Inventory-Datei '$INVENTORY_DIR/hosts.yml' nicht gefunden."
  fi
  debug "Inventory gefunden: $INVENTORY_DIR/hosts.yml"

  # Prüfe Playbook
  if [[ ! -f "$PROJECT_ROOT/site.yml" ]]; then
    error "Playbook '$PROJECT_ROOT/site.yml' nicht gefunden."
  fi
  debug "Playbook gefunden: $PROJECT_ROOT/site.yml"

  info "Voraussetzungen erfolgreich geprüft ✓"
}

validate_profile() {
  local profile=$1

  case "$profile" in
    minimal|standard|full|repair|custom)
      PROFILE_FILE="$CONFIG_DIR/profile_${profile}.yml"
      if [[ ! -f "$PROFILE_FILE" ]]; then
        error "Profil-Datei '$PROFILE_FILE' nicht gefunden."
      fi
      debug "Profil-Datei: $PROFILE_FILE"
      ;;
    *)
      error "Unbekanntes Profil: $profile"
      ;;
  esac
}

build_ansible_command() {
  local cmd="ansible-playbook"
  cmd="$cmd $PROJECT_ROOT/site.yml"
  cmd="$cmd -i $INVENTORY_DIR/hosts.yml"
  cmd="$cmd -e @$PROFILE_FILE"

  # Lokale Konfiguration laden (falls vorhanden)
  if [[ -f "$LOCAL_CONFIG" ]]; then
    cmd="$cmd -e @$LOCAL_CONFIG"
  fi

  # Extra-Variablen hinzufügen
  if [[ -n "${EXTRA_VARS:-}" ]]; then
    cmd="$cmd $EXTRA_VARS"
  fi

  # Dry-Run
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    cmd="$cmd --check --diff"
    warning "DRY-RUN Modus aktiviert"
  fi

  echo "$cmd"
}

################################################################################
# Hauptprogramm
################################################################################

main() {
  # Prüfe Argumente
  if [[ $# -lt 1 ]]; then
    usage
  fi

  local profile="$1"
  shift || true

  # Parse Optionen
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--target)
        EXTRA_VARS="${EXTRA_VARS:-} -e wiz_target=$2"
        shift 2
        ;;
      -i|--infra)
        EXTRA_VARS="${EXTRA_VARS:-} -e do_infra=true"
        shift
        ;;
      -a|--apps)
        EXTRA_VARS="${EXTRA_VARS:-} -e do_apps=true"
        shift
        ;;
      -e|--test)
        EXTRA_VARS="${EXTRA_VARS:-} -e do_test=true"
        shift
        ;;
      -v|--validate)
        EXTRA_VARS="${EXTRA_VARS:-} -e do_validate=true"
        shift
        ;;
      -d|--dry-run)
        DRY_RUN=1
        shift
        ;;
      -h|--help)
        usage
        ;;
      *)
        error "Unbekannte Option: $1"
        ;;
    esac
  done

  # Validiere Profil
  validate_profile "$profile"

  # Prüfe Voraussetzungen
  check_prerequisites

  # Baue Ansible-Befehl
  local ansible_cmd=$(build_ansible_command)

  # Zeige Zusammenfassung
  echo ""
  echo -e "${BLUE}=== DEPLOYMENT ZUSAMMENFASSUNG ===${NC}"
  echo -e "Profil: ${GREEN}$profile${NC}"
  echo -e "Profil-Datei: ${GREEN}$PROFILE_FILE${NC}"
  echo -e "Inventory: ${GREEN}$INVENTORY_DIR/hosts.yml${NC}"
  echo -e "Playbook: ${GREEN}$PROJECT_ROOT/site.yml${NC}"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo -e "Modus: ${YELLOW}DRY-RUN${NC}"
  else
    echo -e "Modus: ${GREEN}LIVE${NC}"
  fi
  echo ""

  # Bestätigung vor Ausführung
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    read -p "Möchtest du fortfahren? (ja/nein): " confirm
    if [[ "$confirm" != "ja" ]]; then
      warning "Deployment abgebrochen"
      exit 0
    fi
  fi

  # Führe Ansible aus
  echo ""
  info "Starte Ansible Playbook..."
  echo -e "${BLUE}Befehl: $ansible_cmd${NC}"
  echo ""

  eval "$ansible_cmd"

  echo ""
  info "Deployment abgeschlossen ✓"
}

# Starte Hauptprogramm
main "$@"
