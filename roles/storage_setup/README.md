# storage_setup Role

Diese Rolle formatiert und mounted Disk 2 unter `/mnt/data_storage` für die Speicherung von Massendaten (Backups, ISOs, Dokumenten, Medien).

## Architektur

Die Storage-Architektur folgt dem "Hybrid Layout" Konzept:

- **Disk 1 (1TB NVMe)**: Proxmox OS + LVM-Thin Pool (für VM-Disks und Container)
- **Disk 2 (2TB SSD)**: ext4 Filesystem, gemountet unter `/mnt/data_storage` (für Backups, ISOs, große Datenmengen)

## Subdirectories

Die Rolle erstellt folgende Subdirectories unter `/mnt/data_storage`:

- `backups/`: VM- und Datenbank-Backups
- `iso_images/`: Cloud-Images und ISO-Dateien
- `paperless_data/`: Paperless-ngx Dokumente und OCR-Daten
- `media/`: Medien-Dateien (später für Jellyfin, etc.)
- `n8n_data/`: N8N Workflows und Daten
- `database_backups/`: PostgreSQL Backups
- `ai_models/`: AI-Modelle (Whisper, Ollama)
- `logs/`: Zentrale Logs

## Verwendung

### Einfaches Mounting (ohne Formatierung)

```bash
ansible-playbook site.yml -e "@config/profile_standard.yml" -t storage_setup
```

### Mit Formatierung (WARNUNG: Alle Daten gehen verloren!)

```bash
ansible-playbook site.yml -e "@config/profile_standard.yml" -e "storage_format_disk=true" -t storage_setup
```

## Konfiguration

Die Rolle wird über `inventory/group_vars/proxmox_servers.yml` konfiguriert:

```yaml
# Disk-Gerät (anpassen basierend auf Hardware)
storage_disk_device: "/dev/sdb"

# Mount-Punkt
storage_mount_path: "/mnt/data_storage"

# Formatierung durchführen? (Standard: false)
storage_format_disk: false
```

## Sicherheitsmaßnahmen

- **Formatierung ist deaktiviert**: Die Rolle formatiert Disk 2 nicht automatisch. Dies muss explizit mit `storage_format_disk=true` aktiviert werden.
- **Warnung vor Formatierung**: Wenn Formatierung aktiviert ist, wird eine Bestätigungspause eingebaut.
- **fstab Eintrag**: Die Rolle trägt die Disk automatisch in `/etc/fstab` ein, damit sie nach Reboots wieder gemountet wird.
- **nofail Option**: Die Mount-Option `nofail` verhindert, dass der Boot fehlschlägt, wenn Disk 2 nicht verfügbar ist.

## Troubleshooting

### Disk nicht erkannt

```bash
# Prüfe verfügbare Disks
lsblk
# oder
ls -la /dev/sd*
```

### Disk bereits formatiert

Die Rolle prüft automatisch, ob die Disk bereits formatiert ist. Wenn ja, wird sie nur gemountet, nicht neu formatiert.

### Mount-Fehler

```bash
# Prüfe aktuellen Mount-Status
mount | grep data_storage

# Prüfe fstab
cat /etc/fstab

# Manuelles Mounting
mount -t ext4 /dev/sdb /mnt/data_storage
```

## Zukünftige Erweiterungen

- **LVM-Thin Pool**: Optionale Erstellung eines LVM-Thin Pools auf Disk 2 für VM-Snapshots
- **Quota Management**: Automatische Quota-Einrichtung für Subdirectories
- **Monitoring**: Integration mit Prometheus für Speicherplatz-Monitoring
