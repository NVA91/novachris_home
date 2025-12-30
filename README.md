# novachris_home - Self-Hosted Cloud mit Ansible

Dieses Repository enthält ein professionelles, modular aufgebautes Ansible-Projekt zur Automatisierung einer privaten, selbstgehosteten Cloud-Infrastruktur. Das Projekt ist speziell für eine hybride Umgebung aus einem Proxmox VE Heimserver und einem externen VPS konzipiert und nutzt ein profilbasiertes "Plugin-System" für die App-Verwaltung.

## Architektur: "The Clean House Strategy"

Die Architektur trennt klar zwischen Infrastruktur, Netzwerk und Anwendungen, um maximale Stabilität, Sicherheit und Wartbarkeit zu gewährleisten.

- **Proxmox Host (GMKtec)**: Dient als reiner Hypervisor ("Vermieter") und stellt nur die notwendigen Ressourcen (CPU, RAM, Storage) bereit. Es laufen keine Services direkt auf dem Host.
- **VPS (Hostinger EPYC)**: Fungiert als "Türsteher" und Cache. Er nimmt den Internet-Traffic entgegen, liefert statische Inhalte aus und leitet Anfragen durch einen sicheren WireGuard-Tunnel zum Heimserver.
- **3 Spezialisierte VMs**:
  - **vm-gateway**: Das Tor zur Welt. Hier endet der WireGuard-Tunnel, und Traefik verteilt als Reverse Proxy die Anfragen an die internen Dienste.
  - **vm-office**: Das digitale Büro. Hier laufen datenintensive Anwendungen wie Paperless-ngx und N8N, die auf eine zentrale PostgreSQL-Datenbank zugreifen.
  - **vm-ai-lab**: Das KI-Labor. Eine dedizierte Maschine für rechenintensive KI-Anwendungen wie Whisper und Ollama, vorbereitet für zukünftiges GPU-Passthrough.

## Features (The Solid Base)

- **Intelligente VM-Provisioning**: Automatische Erstellung und **Anpassung** von VMs (CPU/RAM) aus einem Cloud-Image-Template.
- **Intelligente Hostname-Logik**: Automatische Korrektur des Hostnamens mit anschließendem Reboot.
- **Storage-Architektur**: Saubere Trennung von System- (Disk 1) und Massendaten (Disk 2, gemountet unter `/mnt/data_storage`).
- **Docker-Setup**: Vollautomatische Installation und Konfiguration von Docker und Docker Compose auf den Gast-VMs.
- **Plugin-System für Apps**: Apps werden über das Inventory (`group_vars/proxmox_servers.yml`) definiert und als Docker-Compose-Anwendungen über Templates bereitgestellt.
- **Profilbasiertes Deployment**: Vordefinierte Profile (`minimal`, `standard`, `full`, `repair`) für ein schnelles, konsistentes Deployment. Ein `custom`-Profil ermöglicht eine interaktive Konfiguration.
- **Netzwerk-Automatisierung**: Einrichtung einer `vmbr0`-Bridge auf dem Proxmox-Host und Vorbereitung für WireGuard-Tunneling.
- **Sicherheit**: Integrierte Sicherheits-Best-Practices, einschließlich PVE-Firewall, SSH-Härtung und Secrets-Management mit **Ansible Vault**.

## Quickstart

### 1. Voraussetzungen

- **Ansible**: Auf dem Control-Node installiert.
- **Proxmox VE**: Ein laufender Proxmox-Server.
- **SSH-Zugang**: SSH-Zugriff mit `root`-Rechten auf den Proxmox-Host.

### 2. Konfiguration

1. **Produktionsumgebung einrichten**: Führen Sie `bash setup_prod_env.sh` aus, um ein SSH-Schlüsselpaar zu erzeugen.
2. **Inventory anpassen**:
   - `inventory/hosts.yml`: Tragen Sie die IP-Adresse Ihres Proxmox-Servers ein.
   - `inventory/group_vars/proxmox_servers.yml`: Passen Sie die VM-Definitionen (`guest_vms`) und die App-Konfiguration (`apps_config`) an Ihre Bedürfnisse an.
   - `inventory/host_vars/proxmox-host-01.yml`: Konfigurieren Sie die Proxmox-spezifischen Netzwerk-Variablen (`pve_interface`, `pve_ip`, `pve_gateway`).

### 3. Deployment

Führen Sie das Deployment mit einem der vordefinierten Profile aus. Das Playbook kümmert sich um die Erstellung der VMs, die Installation von Docker und das Deployment der ausgewählten Apps.

- **Standard-Deployment (Gateway + Office)**:
  ```bash
  ansible-playbook site.yml -e "@config/profile_standard.yml"
  ```

- **Vollständiges Deployment (Alle VMs + Alle Apps)**:
  ```bash
  ansible-playbook site.yml -e "@config/profile_full.yml"
  ```

- **Interaktives Deployment**:
  ```bash
  ansible-playbook site.yml -e "@config/profile_custom.yml"
  ```

## Rollen-Übersicht

- **`system_setup`**: Konfiguriert den Proxmox-Host (Repositories, PVE-Firewall, Netzwerk).
- **`user_management`**: Verwaltet Benutzer und SSH-Zugänge auf dem Host und in den VMs.
- **`provision_guests`**: Erstellt die VMs aus einem Cloud-Image-Template.
- **`docker_setup`**: Installiert und konfiguriert Docker und Docker Compose auf den Gast-VMs.
- **`app_deployment`**: Stellt die Docker-Compose-basierten Anwendungen bereit.
- **`qa_smoke`**: Führt Validierungs- und Test-Aufgaben aus.

## Das Plugin-System

Das Herzstück des Projekts ist das flexible Plugin-System. In `inventory/group_vars/proxmox_servers.yml` können Sie unter `apps_config` neue Anwendungen definieren. Jede App benötigt ein entsprechendes Docker-Compose-Template im Verzeichnis `templates/docker-compose/`. Die `deployment_profiles` legen fest, welche Apps in welchem Profil standardmäßig bereitgestellt werden.

## Zukünftige Erweiterungen (Roadmap)

- **Ansible Vault Integration**: Absicherung aller sensiblen Daten (Passwörter, API-Keys).
- **WireGuard-Automatisierung**: Vollständige Konfiguration des Tunnels zwischen VPS und Gateway-VM.
- **GPU-Passthrough**: Automatische Konfiguration des GPU-Passthroughs für die `vm-ai-lab`.
- **Monitoring & Logging**: Integration von Prometheus, Grafana und Loki/Promtail.
- **Backup & Restore**: Automatisierte Backups der VMs und Anwendungsdaten.
