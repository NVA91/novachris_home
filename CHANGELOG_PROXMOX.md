# CHANGELOG - Proxmox VE Spezifische Anpassungen

## Version 2.0 - Proxmox VE Optimierung

Dieses Changelog dokumentiert alle Änderungen, die das Projekt von einem generischen Linux-Automation-Framework zu einem Proxmox VE-spezifischen Deployment-Tool transformiert haben.

### Hauptänderungen

#### 1. Repository Management (system_setup)

**Problem:** Das Projekt nutzte generische `apt update` Befehle, ohne Proxmox-Repositories zu berücksichtigen. Dies führt zu Fehlern bei Systemen ohne Enterprise-Subscription.

**Lösung implementiert:**
- Deaktivierung des `pve-enterprise.list` Repository (da keine Subscription)
- Aktivierung des `pve-no-subscription` Repository
- Automatische Erkennung der Debian-Version (z.B. `bookworm` für PVE 8)
- Hinzufügen des Proxmox Release Keys

**Dateien geändert:**
- `roles/system_setup/tasks/main.yml`: Neue Section "Proxmox Repository Management"
- `roles/system_setup/defaults/main.yml`: Proxmox-Pakete hinzugefügt

#### 2. Firewall Management (system_setup)

**Problem:** UFW (Uncomplicated Firewall) ist inkompatibel mit der Proxmox PVE Firewall und führt zu Konflikten bei Cluster-Kommunikation.

**Lösung implementiert:**
- Entfernung von UFW
- Aktivierung der PVE Firewall (Cluster-Level)
- Konfiguration von SSH- und HTTPS-Regeln in `/etc/pve/firewall/cluster.fw`

**Dateien geändert:**
- `roles/system_setup/tasks/main.yml`: Neue Section "Firewall Management"

#### 3. User Management für Proxmox GUI (user_management)

**Problem:** Benutzer wurden nur als Linux-Systembenutzer erstellt, hatten aber keinen Zugriff auf die Proxmox Web-GUI (Port 8006).

**Lösung implementiert:**
- Integration von `pveum` Befehlen zur Erstellung von Proxmox-Benutzern
- Zuweisung der `PVEAdmin` Rolle
- Automatische Erkennung, ob `pveum` verfügbar ist (für Kompatibilität)

**Dateien geändert:**
- `roles/user_management/tasks/main.yml`: Neue Section "Proxmox User Management (PVE Realm)"

#### 4. SSH-Sicherheit (Cluster-kompatibel) (user_management)

**Problem:** `PermitRootLogin no` blockiert zukünftige Cluster-Kommunikation zwischen Proxmox-Nodes.

**Lösung implementiert:**
- Änderung zu `PermitRootLogin prohibit-password` (nur Key-Auth erlaubt)
- Ermöglicht SSH-Zugriff als Root mit Schlüssel (für Proxmox-Cluster)
- Blockiert Passwort-basierte Root-Authentifizierung

**Dateien geändert:**
- `roles/user_management/tasks/main.yml`: SSH-Konfiguration aktualisiert

#### 5. Netzwerk-Konfiguration (vmbr0 Bridge) (installation_classes)

**Problem:** Generische Netzwerk-Konfiguration berücksichtigte nicht die Proxmox-Anforderung für eine vmbr0-Bridge für VM-Kommunikation.

**Lösung implementiert:**
- Automatische Erstellung der vmbr0-Bridge
- Konfiguration des physischen Interfaces als `manual`
- Verwendung von `ifupdown2` (Proxmox Standard)
- Backup der ursprünglichen Konfiguration
- Async Reload-Handler zur Vermeidung von Verbindungsabbrüchen

**Dateien geändert:**
- `roles/installation_classes/tasks/core/main.yml`: Neue Section "Netzwerk-Konfiguration"
- `roles/system_setup/handlers/main.yml`: Async Reload-Handler hinzugefügt

#### 6. Storage-Konfiguration (LVM-Thin Pools) (installation_classes)

**Problem:** VMs wurden auf der Root-Partition gespeichert, was zu Performance-Problemen und fehlenden Snapshots/Backups führt.

**Lösung implementiert:**
- Automatische Erkennung verfügbarer Festplatten
- Erstellung von LVM Physical Volumes
- Erstellung von Thin Pools für VM-Storage
- Konfiguration in `/etc/pve/storage.cfg`
- Error-Handling für bereits konfigurierte Storage

**Dateien geändert:**
- `roles/installation_classes/tasks/core/main.yml`: Neue Section "Storage-Konfiguration"

#### 7. Kernel-Management (system_setup)

**Problem:** Standard-Debian-Kernel wird statt des Proxmox-Kernels verwendet, was zu Kompatibilitätsproblemen führt.

**Lösung implementiert:**
- Prüfung des laufenden Kernels
- Warnung, wenn Standard-Debian-Kernel lädt
- Optional: Entfernung des Standard-Kernels (mit Flag `remove_debian_kernel`)

**Dateien geändert:**
- `roles/system_setup/tasks/main.yml`: Neue Section "Kernel und Reboot Management"

#### 8. Hostname-Validierung (system_setup)

**Problem:** Hostname-Änderungen bei laufendem Proxmox können zum Ausfall des pve-cluster Services führen.

**Lösung implementiert:**
- Validierung, dass Inventory-Hostname mit System-Hostname übereinstimmt
- Abbruch statt blindem Ändern
- Warnung für manuelle Schritte bei Mismatch

**Dateien geändert:**
- `roles/system_setup/tasks/main.yml`: Neue Section "Systemkonfiguration"

#### 9. Netzwerk-Sicherheitsnetz (site.yml)

**Problem:** Netzwerkänderungen können zu Verbindungsabbrüchen führen, wenn sie fehlerhaft sind.

**Lösung implementiert:**
- Automatische Planung eines Reboots (+10 Minuten)
- Validierung der Verbindung nach Netzwerkänderungen
- Automatischer Abbruch des Reboots bei Erfolg
- Timeout-Handling

**Dateien geändert:**
- `site.yml`: Neue Tasks "2.2 Netzwerk-Sicherheitsnetz: Auto-Reboot einplanen" und "2.6-2.7"

#### 10. Variablen-Struktur (inventory)

**Problem:** Generische Netzwerk-Variablen reichten nicht für Proxmox-spezifische Konfiguration.

**Lösung implementiert:**
- Neue Variablen: `pve_interface`, `pve_ip`, `pve_gateway`
- Storage-Variablen: `storage_device`, `storage_vg_name`, `storage_thin_pool`
- Proxmox-spezifische Variablen: `proxmox_version`, `proxmox_role`

**Dateien geändert:**
- `inventory/host_vars/proxmox-host-01.yml`: Umfassend erweitert
- `inventory/group_vars/proxmox_servers.yml`: Proxmox-Variablen hinzugefügt

### Neue Dateien

- `CHANGELOG_PROXMOX.md`: Dieses Changelog

### Aktualisierte Dateien

| Datei | Änderungen |
|-------|-----------|
| `roles/system_setup/tasks/main.yml` | Proxmox Repos, Firewall, Kernel-Management |
| `roles/system_setup/defaults/main.yml` | Proxmox-Pakete, `remove_debian_kernel` Flag |
| `roles/system_setup/handlers/main.yml` | Async Reload-Handler |
| `roles/user_management/tasks/main.yml` | PVE User Management, SSH-Sicherheit |
| `roles/installation_classes/tasks/core/main.yml` | vmbr0-Bridge, LVM-Storage, Cluster-Validierung |
| `inventory/host_vars/proxmox-host-01.yml` | Proxmox-spezifische Variablen |
| `inventory/group_vars/proxmox_servers.yml` | Proxmox-Variablen |
| `site.yml` | Netzwerk-Sicherheitsnetz-Tasks |
| `README.md` | Proxmox-spezifische Dokumentation |

### Kompatibilität

- **Proxmox VE Versionen:** 7.x, 8.x (getestet mit 8.0)
- **Debian Versionen:** Bullseye (PVE 7), Bookworm (PVE 8)
- **Ansible Versionen:** 2.9+

### Migration von Version 1.x zu 2.0

Wenn Sie von Version 1.x migrieren, beachten Sie:

1. **Backup erstellen:** Sichern Sie Ihre aktuelle Konfiguration
2. **Variablen anpassen:** Überprüfen Sie `inventory/host_vars/` auf neue Variablen
3. **Test durchführen:** Führen Sie einen Dry-Run durch: `bash wizzad.sh standard --dry-run`
4. **Deployment:** Führen Sie das Deployment durch: `bash wizzad.sh standard`

### Bekannte Limitierungen

1. **Hostname-Änderungen:** Können nicht automatisch durchgeführt werden, wenn Proxmox bereits läuft
2. **Cluster-Konfiguration:** Cluster-Setup ist noch nicht automatisiert (geplant für v2.1)
3. **Backup-Integration:** Proxmox Backup Server Integration ist noch nicht implementiert (geplant für v2.2)

### Zukünftige Verbesserungen (Roadmap)

- [ ] Proxmox Cluster-Setup automatisieren
- [ ] Proxmox Backup Server Integration
- [ ] VM-Template-Management
- [ ] Monitoring-Integration (Grafana, Prometheus)
- [ ] Automatische Backup-Verifikation
- [ ] High-Availability (HA) Konfiguration

### Feedback und Beiträge

Feedback und Verbesserungsvorschläge sind willkommen! Bitte erstellen Sie ein Issue oder einen Pull Request.
