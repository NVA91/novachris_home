# RUNBOOK_MOVE.md - Hardware-Migrations-Runbook

Dieses Runbook beschreibt die Schritte für den Umzug der novachris_home-Installation auf neue Hardware.

## Übersicht

Der Migrations-Prozess besteht aus folgenden Phasen:

1. **Vorbereitung** - Planung und Backup
2. **Inventar-Anpassung** - Neue Hardware-Informationen
3. **Preview** - Überprüfung der geplanten Änderungen
4. **Deployment** - Ausführung des Playbooks
5. **Validierung** - Überprüfung der Installation
6. **Daten-Wiederherstellung** - Restore von Backups (optional)

## Phase 1: Vorbereitung

### 1.1 Backup erstellen

Sichern Sie alle kritischen Daten und Konfigurationen:

```bash
# Backup des aktuellen Systems
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz \
  /opt/novachris_home \
  /etc/ansible \
  ~/.wizzad/keys

# Backup in sicheres Verzeichnis verschieben
mv backup_*.tar.gz /mnt/backup/
```

### 1.2 Dokumentation überprüfen

- [ ] Aktuelle Konfiguration dokumentieren
- [ ] Alle installierten Services auflisten
- [ ] Abhängigkeiten überprüfen
- [ ] Bekannte Probleme dokumentieren

### 1.3 Neue Hardware vorbereiten

- [ ] Proxmox VE installieren
- [ ] Netzwerk konfigurieren
- [ ] SSH-Zugriff aktivieren
- [ ] Root-Zugang sicherstellen

## Phase 2: Inventar-Anpassung

### 2.1 Neue Host-Informationen sammeln

Sammeln Sie folgende Informationen über die neue Hardware:

| Information | Wert |
|------------|------|
| Hostname | z.B. proxmox-new-01 |
| IP-Adresse | z.B. 192.168.1.200 |
| SSH-Port | z.B. 22 |
| Benutzer | z.B. root |
| CPU-Kerne | z.B. 16 |
| RAM (GB) | z.B. 64 |
| Disk (GB) | z.B. 500 |

### 2.2 Inventory aktualisieren

Bearbeiten Sie `inventory/hosts.yml`:

```yaml
---
all:
  children:
    proxmox_servers:
      hosts:
        proxmox-new-01:              # Neuer Hostname
          ansible_host: 192.168.1.200  # Neue IP
          ansible_user: root
          ansible_port: 22
```

### 2.3 Host-Variablen aktualisieren

Erstellen Sie `inventory/host_vars/proxmox-new-01.yml`:

```yaml
---
# Host-spezifische Variablen für proxmox-new-01

ansible_user: root
ansible_port: 22

hostname: proxmox-new-01
domain: example.local
fqdn: "{{ hostname }}.{{ domain }}"

# Netzwerk
ip_address: 192.168.1.200
gateway: 192.168.1.1
netmask: 255.255.255.0

# Ressourcen
cpu_cores: 16
memory_gb: 64
disk_gb: 500

# Rollen
proxmox_role: hypervisor
cluster_member: false
```

### 2.4 Gruppenvariablen überprüfen

Überprüfen Sie `inventory/group_vars/proxmox_servers.yml` und passen Sie bei Bedarf an:

```yaml
---
# Proxmox-spezifische Einstellungen
proxmox_version: "8.0"
vm_template_name: ubuntu-2204-cloud

# Storage
storage_location: /var/lib/vz

# Backup
backup_storage: /mnt/backup
```

## Phase 3: Preview

### 3.1 Host-Liste überprüfen

Überprüfen Sie, welche Hosts betroffen sind:

```bash
ansible-playbook site.yml -i inventory/hosts.yml --list-hosts
```

Erwartete Ausgabe:

```
  proxmox-new-01
  controller
```

### 3.2 Dry-Run durchführen

Führen Sie einen Dry-Run durch, um die geplanten Änderungen einzusehen:

```bash
bash wizzad.sh standard --dry-run
```

oder

```bash
ansible-playbook site.yml -i inventory/hosts.yml --check --diff
```

### 3.3 Änderungen überprüfen

Überprüfen Sie die geplanten Änderungen:

- [ ] Richtige Hosts werden konfiguriert
- [ ] Richtige Rollen werden ausgeführt
- [ ] Keine unerwarteten Änderungen
- [ ] Alle erforderlichen Variablen gesetzt

## Phase 4: Deployment

### 4.1 Profil auswählen

Wählen Sie das passende Profil:

- **standard**: Infrastruktur + Apps (empfohlen)
- **full**: Infrastruktur + Apps + Tests
- **minimal**: Nur System-Setup

### 4.2 Deployment starten

```bash
# Standard-Deployment
bash wizzad.sh standard

# oder mit Dry-Run zuerst
bash wizzad.sh standard --dry-run
# dann ohne Dry-Run
bash wizzad.sh standard
```

### 4.3 Deployment überwachen

Überwachen Sie die Ansible-Ausgabe auf:

- [ ] Keine kritischen Fehler
- [ ] Alle Tasks erfolgreich
- [ ] Abschlussmeldung erhalten

## Phase 5: Validierung

### 5.1 QA Smoke Tests überprüfen

Überprüfen Sie die QA Smoke Test Ergebnisse:

```bash
# Log überprüfen
cat /var/log/novachris_home/qa_smoke.log

# Status sollte "green" sein
```

### 5.2 Services überprüfen

Überprüfen Sie den Status der Services:

```bash
# SSH-Verbindung testen
ssh -i ~/.wizzad/keys/id_ed25519_prod admin_novachris@192.168.1.200

# Services überprüfen
systemctl status
```

### 5.3 Konfiguration validieren

Überprüfen Sie wichtige Konfigurationsdateien:

```bash
# Hostname
hostname

# Netzwerk
ip addr show

# Speicherplatz
df -h

# Benutzer
id admin_novachris
```

### 5.4 Connectivity testen

Testen Sie die Verbindung zu anderen Systemen:

```bash
# Gateway erreichbar?
ping 192.168.1.1

# DNS funktioniert?
nslookup example.com

# Internet erreichbar?
ping 8.8.8.8
```

## Phase 6: Daten-Wiederherstellung (Optional)

### 6.1 Backup-Quelle vorbereiten

Stellen Sie sicher, dass das Backup verfügbar ist:

```bash
# Backup-Verzeichnis überprüfen
ls -lh /mnt/backup/

# Backup-Größe überprüfen
du -sh /mnt/backup/backup_*.tar.gz
```

### 6.2 Backup extrahieren

Extrahieren Sie das Backup auf dem neuen System:

```bash
# Backup auf neues System kopieren
scp /mnt/backup/backup_*.tar.gz admin_novachris@192.168.1.200:/tmp/

# Auf neuem System extrahieren
ssh admin_novachris@192.168.1.200
tar -xzf /tmp/backup_*.tar.gz -C /
```

### 6.3 Datenintegrität überprüfen

Überprüfen Sie die Integrität der wiederhergestellten Daten:

```bash
# Wichtige Verzeichnisse überprüfen
ls -la /opt/novachris_home
ls -la /etc/ansible

# Dateigröße überprüfen
du -sh /opt/novachris_home
```

## Rollback-Plan

Falls etwas schief geht:

### Schneller Rollback

1. **Alte Hardware wieder aktivieren** (falls noch vorhanden)
2. **Backup wiederherstellen** auf alter Hardware
3. **Services neu starten**

### Schrittweiser Rollback

1. **Deployment stoppen** (Ansible abbrechen)
2. **Logs überprüfen** (`logs/ansible.log`)
3. **Problem identifizieren** und beheben
4. **Deployment wiederholen**

## Checkliste für Hardware-Migration

Vor der Migration:

- [ ] Backup erstellt und überprüft
- [ ] Neue Hardware vorbereitet
- [ ] Inventory aktualisiert
- [ ] Host-Variablen erstellt
- [ ] Dry-Run erfolgreich

Während der Migration:

- [ ] Deployment gestartet
- [ ] Deployment überwacht
- [ ] Keine Fehler aufgetreten

Nach der Migration:

- [ ] QA Smoke Tests grün
- [ ] Services laufen
- [ ] Konfiguration korrekt
- [ ] Connectivity getestet
- [ ] Daten wiederhergestellt (falls nötig)

## Troubleshooting

### Problem: SSH-Verbindung fehlgeschlagen

```bash
# SSH-Konfiguration überprüfen
ssh -v admin_novachris@192.168.1.200

# SSH-Key überprüfen
ls -la ~/.wizzad/keys/id_ed25519_prod*

# SSH-Berechtigungen überprüfen
chmod 600 ~/.wizzad/keys/id_ed25519_prod
chmod 644 ~/.wizzad/keys/id_ed25519_prod.pub
```

### Problem: Deployment fehlgeschlagen

```bash
# Logs überprüfen
cat logs/ansible.log

# Preflight-Checks manuell durchführen
ansible proxmox-new-01 -m ping
ansible proxmox-new-01 -m command -a "id -u" --become

# Dry-Run erneut durchführen
bash wizzad.sh standard --dry-run
```

### Problem: Services laufen nicht

```bash
# Service-Status überprüfen
systemctl status service-name

# Service-Logs überprüfen
journalctl -u service-name -n 50

# Service neu starten
systemctl restart service-name
```

## Weitere Ressourcen

- [README.md](README.md) - Projektübersicht
- [RELEASE_GATE.md](RELEASE_GATE.md) - Release Gate Checklist
- [SECURITY.md](SECURITY.md) - Sicherheitsrichtlinien
