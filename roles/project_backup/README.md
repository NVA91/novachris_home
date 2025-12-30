# project_backup Role

Diese Rolle ist für die Sicherung der kritischen Daten und Konfigurationen zuständig.

## Aufgaben

- Backup-Verzeichnis erstellen
- Backup-Konfiguration validieren
- Backup-Logik implementieren (TODO)

## Variablen

| Variable | Default | Beschreibung |
|----------|---------|-------------|
| `backup_base_dir` | /mnt/backup | Basis-Verzeichnis für Backups |
| `backup_enabled` | true | Backup aktivieren |
| `backup_retention_days` | 30 | Aufbewahrungsdauer in Tagen |
| `backup_schedule` | daily | Backup-Zeitplan |

## Tags

- `project_backup`: Alle Tasks dieser Rolle
- `backup`: Backup-Tasks

## Zukünftige Implementierung

Diese Rolle wird erweitert um:
- rsync-basierte Backups
- Borg Backup Integration
- Proxmox Backup Server Integration
- Backup-Verifikation
- Restore-Tests
