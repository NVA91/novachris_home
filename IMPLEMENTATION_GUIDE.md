# Implementierungs-Anleitung: novachris_home Self-Hosted Cloud

Diese Anleitung führt Sie Schritt für Schritt durch die Implementierung der Self-Hosted Cloud Infrastruktur mit Ansible.

## Phase 1: Vorbereitung

### 1.1 Systemvoraussetzungen

Stellen Sie sicher, dass folgende Komponenten vorhanden sind:

- **Proxmox VE 8.x** auf einem lokalen Server (z.B. GMKtec K12)
- **VPS mit Debian/Ubuntu** (z.B. Hostinger EPYC) für WireGuard-Tunnel
- **Ansible 2.9+** auf Ihrem Control-Node (Laptop/Workstation)
- **SSH-Zugriff** mit `root`-Rechten auf den Proxmox-Host

### 1.2 Repository klonen

```bash
git clone https://github.com/yourusername/novachris_home.git
cd novachris_home
```

### 1.3 Produktionsumgebung einrichten

Führen Sie das Setup-Skript aus, um SSH-Schlüssel zu erzeugen:

```bash
bash setup_prod_env.sh
```

Dies erstellt:
- Ein SSH-Schlüsselpaar unter `~/.wizzad/keys/`
- Eine lokale Konfigurationsdatei `.wizzad.local.yml` (wird von Git ignoriert)

Kopieren Sie den öffentlichen Schlüssel auf Ihren Proxmox-Host:

```bash
ssh-copy-id -i ~/.wizzad/keys/id_ed25519_prod.pub root@proxmox-host-ip
```

## Phase 2: Konfiguration

### 2.1 Inventory anpassen

**Datei: `inventory/hosts.yml`**

Tragen Sie die IP-Adresse Ihres Proxmox-Servers ein:

```yaml
proxmox_servers:
  hosts:
    proxmox-host-01:
      ansible_host: 192.168.1.100
      ansible_user: root
      ansible_ssh_private_key_file: ~/.wizzad/keys/id_ed25519_prod
```

### 2.2 Proxmox-Konfiguration

**Datei: `inventory/host_vars/proxmox-host-01.yml`**

Passen Sie die Netzwerk-Variablen an Ihre Umgebung an:

```yaml
# Physisches Interface (prüfen mit: ip a)
pve_interface: eno1

# Management IP und Gateway
pve_ip: 192.168.1.100/24
pve_gateway: 192.168.1.1
```

### 2.3 VM- und App-Konfiguration

**Datei: `inventory/group_vars/proxmox_servers.yml`**

Die VM-Definitionen sind bereits vorkonfiguriert. Passen Sie bei Bedarf an:

```yaml
guest_vms:
  - name: "vm-gateway"
    vmid: 100
    cores: 2
    memory: 2048
    # ...weitere Konfiguration

  - name: "vm-office"
    vmid: 110
    cores: 4
    memory: 8192
    # ...weitere Konfiguration

  - name: "vm-ai-lab"
    vmid: 120
    cores: 6
    memory: 8192
    # ...weitere Konfiguration
```

Die App-Konfiguration definiert, welche Docker-Compose-Anwendungen auf welchen VMs laufen:

```yaml
apps_config:
  wireguard-client:
    vm: "vm-gateway"
    type: "docker-compose"
    template: "wireguard-client.yml"
    # ...weitere Konfiguration

  paperless-ngx:
    vm: "vm-office"
    type: "docker-compose"
    template: "paperless-ngx.yml"
    # ...weitere Konfiguration
```

### 2.4 Secrets konfigurieren (optional)

Für die Sicherheit sollten Sie Ansible Vault verwenden, um sensible Daten zu schützen. Erstellen Sie eine `secrets.yml`:

```bash
ansible-vault create inventory/group_vars/vault.yml
```

Fügen Sie folgende Variablen hinzu:

```yaml
vault_postgres_password: "your-secure-password"
vault_paperless_admin_password: "your-secure-password"
vault_n8n_admin_password: "your-secure-password"
vault_wireguard_private_key: "your-wireguard-key"
```

## Phase 3: Deployment

### 3.1 Dry-Run durchführen

Vor dem echten Deployment empfiehlt sich ein Dry-Run, um potenzielle Probleme zu identifizieren:

```bash
ansible-playbook site.yml -e "@config/profile_standard.yml" --check
```

### 3.2 Deployment mit Profilen

Wählen Sie ein vordefiniertes Profil für Ihr Deployment:

**Minimal (nur Gateway-VM):**
```bash
ansible-playbook site.yml -e "@config/profile_minimal.yml" -v
```

**Standard (Gateway + Office):**
```bash
ansible-playbook site.yml -e "@config/profile_standard.yml" -v
```

**Full (Alle VMs + Alle Apps):**
```bash
ansible-playbook site.yml -e "@config/profile_full.yml" -v
```

**Repair (Reparatur-Modus):**
```bash
ansible-playbook site.yml -e "@config/profile_repair.yml" -v
```

**Custom (Interaktiv):**
```bash
ansible-playbook site.yml -e "@config/profile_custom.yml" -v
```

Das Playbook wird:
1. Den Proxmox-Host konfigurieren (Repositories, Firewall, Netzwerk)
2. Die VMs erstellen (aus Cloud-Image-Template)
3. Docker auf den VMs installieren
4. Die Docker-Compose-Anwendungen bereitstellen
5. Validierungs-Tests durchführen

## Phase 4: Verifikation

Nach dem erfolgreichen Deployment überprüfen Sie:

### 4.1 VMs prüfen

```bash
# SSH in die Gateway-VM
ssh admin@vm-gateway.example.local

# Docker-Container prüfen
docker ps
```

### 4.2 Services testen

- **Traefik Dashboard**: http://localhost:8080
- **Paperless**: http://localhost:8000
- **N8N**: http://localhost:5678
- **Whisper API**: http://localhost:9000
- **Ollama**: http://localhost:11434

### 4.3 Logs überprüfen

```bash
# Ansible-Logs
tail -f /var/log/novachris_home/deployment.log

# Docker-Logs
docker logs paperless-ngx
docker logs n8n
```

## Phase 5: Konfiguration nach dem Deployment

### 5.1 WireGuard-Tunnel einrichten

Konfigurieren Sie den WireGuard-Tunnel zwischen Ihrem VPS und der Gateway-VM:

1. Generieren Sie Schlüsselpaare auf dem VPS und der Gateway-VM
2. Tragen Sie die öffentlichen Schlüssel gegenseitig ein
3. Testen Sie die Verbindung: `ping 10.0.0.1` (WireGuard-Netzwerk)

### 5.2 DNS-Einträge

Erstellen Sie DNS-Einträge für Ihre Domains:

```
paperless.example.com  → VPS-IP
n8n.example.com        → VPS-IP
app.example.com        → VPS-IP
```

### 5.3 Traefik konfigurieren

Passen Sie die Traefik-Konfiguration an, um HTTPS/SSL zu aktivieren und die Reverse-Proxy-Regeln zu definieren.

## Phase 6: Wartung und Updates

### 6.1 Regelmäßige Updates

Führen Sie regelmäßig Updates durch:

```bash
ansible-playbook site.yml -e "@config/profile_standard.yml" -t docker_setup
```

### 6.2 Backups

Sichern Sie regelmäßig:
- VM-Snapshots (über Proxmox)
- Anwendungsdaten (PostgreSQL, Paperless-Dokumente)
- Konfigurationsdateien

### 6.3 Monitoring

Überwachen Sie die Systemgesundheit:

```bash
# SSH in Proxmox
ssh root@proxmox-host

# VM-Status prüfen
qm list

# Storage-Auslastung
df -h /var/lib/vz
```

## Troubleshooting

### Problem: VMs werden nicht erstellt

**Ursache**: Cloud-Image konnte nicht heruntergeladen werden oder Template-Erstellung fehlgeschlagen.

**Lösung**:
1. Überprüfen Sie die Internetverbindung
2. Prüfen Sie den Speicherplatz auf dem Proxmox-Host: `df -h /var/lib/vz`
3. Löschen Sie das alte Template: `qm destroy 9000`
4. Führen Sie das Playbook erneut aus

### Problem: Docker-Container starten nicht

**Ursache**: Docker-Konfiguration oder Abhängigkeiten fehlgeschlagen.

**Lösung**:
1. SSH in die VM: `ssh admin@vm-gateway`
2. Prüfen Sie Docker-Logs: `docker logs <container-name>`
3. Überprüfen Sie die Docker-Compose-Datei: `docker compose config`
4. Starten Sie den Container neu: `docker compose restart`

### Problem: Netzwerk-Konnektivität

**Ursache**: vmbr0-Bridge nicht korrekt konfiguriert.

**Lösung**:
1. Überprüfen Sie die Netzwerk-Konfiguration: `cat /etc/network/interfaces`
2. Starten Sie das Netzwerk neu: `ifreload -a`
3. Prüfen Sie die Verbindung: `ping vm-gateway`

## Nächste Schritte

Nach erfolgreichem Deployment:

1. **GPU-Passthrough aktivieren**: Wenn Sie eine eGPU einbauen, aktivieren Sie das GPU-Passthrough für die `vm-ai-lab`
2. **Monitoring einrichten**: Implementieren Sie Prometheus/Grafana für Systemüberwachung
3. **Backup-Lösung**: Konfigurieren Sie Proxmox Backup Server oder ähnliche Lösungen
4. **Skalierung**: Erweitern Sie das System mit zusätzlichen VMs oder Apps

## Support und Dokumentation

- **README.md**: Allgemeine Projektbeschreibung
- **SECURITY.md**: Sicherheitsrichtlinien
- **RELEASE_GATE.md**: Deployment-Checkliste
- **RUNBOOK_MOVE.md**: Hardware-Migrations-Handbuch
- **CHANGELOG_PROXMOX.md**: Detaillierte Änderungen
