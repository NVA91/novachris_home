#!/bin/bash

################################################################################
# novachris_home - Setup Produktionsumgebung
# Erzeugt SSH-Keypair und lokale Konfiguration
################################################################################

set -euo pipefail

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verzeichnisse
KEY_DIR="$HOME/.wizzad/keys"
KEY_FILE="$KEY_DIR/id_ed25519_prod"
LOCAL_CONFIG=".wizzad.local.yml"

info() {
  echo -e "${GREEN}INFO: $1${NC}"
}

warning() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

error() {
  echo -e "${RED}ERROR: $1${NC}" >&2
  exit 1
}

main() {
  echo -e "${BLUE}=== novachris_home Setup Produktionsumgebung ===${NC}"
  echo ""

  # 1. Lokales Schlüsselverzeichnis anlegen
  info "Erstelle Schlüssel-Verzeichnis: $KEY_DIR"
  mkdir -p "$KEY_DIR"
  chmod 700 "$KEY_DIR"

  # 2. SSH-Keypair erzeugen (idempotent)
  if [[ -f "$KEY_FILE" ]]; then
    warning "SSH-Key '$KEY_FILE' existiert bereits."
    read -p "Möchtest du einen neuen Key generieren? (ja/nein): " regenerate
    if [[ "$regenerate" != "ja" ]]; then
      info "Verwende bestehenden Key"
    else
      rm -f "$KEY_FILE" "$KEY_FILE.pub"
      info "Generiere neues SSH-Keypair..."
      ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "novachris_home_prod" || error "SSH-Key Generierung fehlgeschlagen"
      info "Neuer SSH-Key erstellt ✓"
    fi
  else
    info "Generiere neues SSH-Keypair..."
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "novachris_home_prod" || error "SSH-Key Generierung fehlgeschlagen"
    info "SSH-Key erstellt ✓"
  fi

  # 3. Berechtigungen setzen
  chmod 600 "$KEY_FILE"
  chmod 644 "$KEY_FILE.pub"

  # 4. .wizzad.local.yml schreiben/aktualisieren
  info "Aktualisiere lokale Konfiguration: $LOCAL_CONFIG"

  cat > "$LOCAL_CONFIG" << EOF
# Lokale Konfiguration für novachris_home
# WARNUNG: Diese Datei enthält sensitive Informationen!
# Sie wird durch .gitignore ausgeschlossen und darf nicht ins Repository committed werden.

# SSH-Schlüssel-Pfade
ansible_ssh_private_key_file: $KEY_FILE
ssh_key_path: ${KEY_FILE}.pub

# Zusätzliche lokale Variablen können hier hinzugefügt werden
# z.B.:
# proxmox_api_token_id: "{{ vault_proxmox_api_token_id }}"
# proxmox_api_token_secret: "{{ vault_proxmox_api_token_secret }}"

EOF

  chmod 600 "$LOCAL_CONFIG"

  # 5. Zusammenfassung
  echo ""
  echo -e "${BLUE}=== SETUP ABGESCHLOSSEN ===${NC}"
  echo ""
  echo -e "SSH-Schlüssel:"
  echo -e "  ${GREEN}Private Key:${NC} $KEY_FILE"
  echo -e "  ${GREEN}Public Key:${NC} ${KEY_FILE}.pub"
  echo ""
  echo -e "Lokale Konfiguration:"
  echo -e "  ${GREEN}Datei:${NC} $LOCAL_CONFIG"
  echo ""
  echo -e "Nächste Schritte:"
  echo -e "  1. Kopiere den öffentlichen Schlüssel auf deine Proxmox-Server:"
  echo -e "     ${YELLOW}cat ${KEY_FILE}.pub${NC}"
  echo -e "  2. Füge den Schlüssel zu ~/.ssh/authorized_keys hinzu"
  echo -e "  3. Starte das Deployment mit:"
  echo -e "     ${YELLOW}bash wizzad.sh standard${NC}"
  echo ""
  info "Setup erfolgreich abgeschlossen ✓"
}

main "$@"
