# installation_classes Role

Diese Rolle gruppiert Installations- und Konfigurations-Tasks in logische Klassen (Core, Apps, Maintenance), gesteuert durch die Flags `do_infra`, `do_apps` und `do_test`.

## Aufgaben

Die Rolle besteht aus drei Hauptklassen:

**Core Infrastructure (do_infra)**
- Proxmox VE Basis-Konfiguration
- Docker Installation
- Storage-Konfiguration
- Netzwerk-Konfiguration

**Applications (do_apps)**
- Service-Deployment
- Backup-Tools
- Monitoring-Tools
- Log-Aggregation

**Maintenance & Testing (do_test)**
- System-Updates
- Log-Rotation
- Disk-Cleanup
- Backup-Verification

## Variablen

Diese Rolle wird durch die folgenden Flags gesteuert:

| Flag | Beschreibung |
|------|-------------|
| `do_infra` | Core-Infrastruktur installieren |
| `do_apps` | Applikationen installieren |
| `do_test` | Maintenance & Tests ausführen |

## Tags

- `installation_classes`: Alle Tasks dieser Rolle
- `core`: Core-Infrastructure-Tasks
- `infrastructure`: Infrastructure-Tasks
- `apps`: Application-Tasks
- `applications`: Application-Tasks
- `maintenance`: Maintenance-Tasks
- `testing`: Testing-Tasks

## Struktur

```
roles/installation_classes/
├── tasks/
│   ├── main.yml
│   ├── core/
│   │   └── main.yml
│   ├── apps/
│   │   └── main.yml
│   └── maintenance/
│       └── main.yml
├── defaults/
│   └── main.yml
└── README.md
```
