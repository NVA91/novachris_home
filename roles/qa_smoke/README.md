# qa_smoke Role

Diese Rolle führt schnelle, nicht-invasive Tests durch, um die grundlegende Funktionsfähigkeit des Systems nach dem Deployment zu überprüfen.

## Aufgaben

Die Rolle führt zwei Arten von Tests durch:

**Preflight Checks**
- Sudo-Rechte prüfen
- Freien Speicherplatz prüfen
- Python3-Verfügbarkeit prüfen

**Post-Deploy Checks**
- Docker-Verfügbarkeit prüfen
- Docker-Netzwerk prüfen
- Container-Status prüfen

## Status-Codes

| Status | Bedeutung |
|--------|-----------|
| green | Alle Tests erfolgreich |
| yellow | Warnungen (z.B. Docker nicht verfügbar) |
| red | Kritische Fehler (z.B. Sudo-Fehler) |

## Variablen

| Variable | Default | Beschreibung |
|----------|---------|-------------|
| `do_validate` | true | QA-Validierung aktivieren |
| `qa_ports` | [22, 80] | Zu prüfende Ports |
| `qa_urls` | ["http://localhost"] | Zu prüfende URLs |
| `qa_docker_network` | novachris_home_net | Docker-Netzwerk-Name |
| `qa_containers` | [] | Container-Namen zum Prüfen |
| `log_dir` | /var/log/novachris_home | Log-Verzeichnis |

## Tags

- `qa_smoke`: Alle Tasks dieser Rolle
- `preflight`: Preflight-Check-Tasks
- `post_deploy`: Post-Deploy-Check-Tasks
- `logging`: Logging-Tasks

## Ausgabe

Die Rolle schreibt die Ergebnisse in:
- `{{ log_dir }}/qa_smoke.log` - Detailliertes Log
- Ansible Debug-Output - Zusammenfassung
