# RELEASE_GATE.md - Release Gate Checklist

Diese Checkliste stellt sicher, dass das Deployment sicher und zuverlässig durchgeführt wird.

## Gate 0: Vorbereitung und Validierung

| Prüfung | Beschreibung | Befehl/Aktion |
|---------|-------------|---------------|
| **Inventory Check** | Inventory und Ziel-Hosts korrekt | Passen Sie `inventory/hosts.yml` und die Gruppenvariablen an Ihre Umgebung an |
| **SSH-Key Setup** | SSH-Schlüssel generiert | `bash setup_prod_env.sh` |
| **Profil-Auswahl** | Richtiges Profil ausgewählt | Überprüfen Sie, welches Profil Sie verwenden möchten (minimal/standard/full/repair) |
| **Backup** | Backup der aktuellen Konfiguration | Sichern Sie kritische Daten vor dem Deployment |

## Gate 1: Host-Validierung

| Prüfung | Beschreibung | Befehl |
|---------|-------------|--------|
| **Host-Liste** | Liste der Ziel-Hosts stimmt | `ansible-playbook site.yml -i inventory/hosts.yml --list-hosts` |
| **Inventar-Syntax** | Inventory-Syntax ist korrekt | `ansible-inventory -i inventory/hosts.yml --list` |
| **Connectivity** | Verbindung zu Ziel-Hosts möglich | `ansible all -i inventory/hosts.yml -m ping` |

## Gate 2: Dry-Run und Planung

| Prüfung | Beschreibung | Befehl |
|---------|-------------|--------|
| **Syntax-Check** | Playbook-Syntax ist korrekt | `ansible-playbook site.yml --syntax-check` |
| **Dry-Run** | Dry-Run ohne Fehler | `bash wizzad.sh <profile> --dry-run` |
| **Diff-Anzeige** | Geplante Änderungen überprüfen | `ansible-playbook site.yml -i inventory/hosts.yml --check --diff` |

## Gate 3: Preflight-Checks

| Prüfung | Beschreibung | Befehl |
|---------|-------------|--------|
| **OS-Kompatibilität** | Ziel-OS wird unterstützt | Prüfen Sie, ob Debian/Ubuntu oder RedHat/CentOS installiert ist |
| **Speicherplatz** | Ausreichend freier Speicherplatz | Mindestens 500 MB auf `/` und App-Pfad |
| **Sudo-Rechte** | Sudo-Rechte vorhanden | `ansible all -i inventory/hosts.yml -m command -a "id -u" --become` |
| **Python3** | Python3 installiert | `ansible all -i inventory/hosts.yml -m command -a "python3 --version"` |

## Gate 4: QA Smoke Tests

| Prüfung | Beschreibung | Befehl |
|---------|-------------|--------|
| **QA Status** | QA-Status ist grün | Die QA-Rolle setzt `qa_status` auf `green` |
| **QA Log** | QA-Log vorhanden | Log unter `/var/log/novachris_home/qa_smoke.log` |
| **Keine Fehler** | Keine kritischen Fehler (red) | Überprüfen Sie das QA-Log auf rote Status-Meldungen |
| **Warnungen** | Warnungen (yellow) überprüfen | Überprüfen Sie, ob Warnungen akzeptabel sind |

## Gate 5: Deployment

| Prüfung | Beschreibung | Aktion |
|---------|-------------|--------|
| **Bestätigung** | Bestätigung vor Live-Deployment | Bestätigen Sie mit "ja" |
| **Monitoring** | Deployment überwachen | Überwachen Sie die Ansible-Ausgabe auf Fehler |
| **Fehlerbehandlung** | Fehler sofort beheben | Bei Fehlern: Logs überprüfen und Probleme beheben |

## Gate 6: Post-Deployment Validierung

| Prüfung | Beschreibung | Befehl |
|---------|-------------|--------|
| **Erfolgs-Meldung** | Deployment erfolgreich abgeschlossen | Überprüfen Sie die Abschlussmeldung |
| **QA Smoke Tests** | QA-Tests erfolgreich | Überprüfen Sie `/var/log/novachris_home/qa_smoke.log` |
| **Service-Status** | Alle Services laufen | `systemctl status` auf Ziel-Hosts |
| **Konfiguration** | Konfiguration korrekt | Überprüfen Sie wichtige Konfigurationsdateien |

## Gate 7: Restore-Test (Optional)

| Prüfung | Beschreibung | Aktion |
|---------|-------------|--------|
| **Backup-Verifikation** | Backup erfolgreich erstellt | Überprüfen Sie Backup-Verzeichnis |
| **Restore-Test** | Restore-Prozess testen | Führen Sie einen Restore-Test durch (optional) |
| **Datenintegrität** | Daten nach Restore intakt | Überprüfen Sie Datenintegrität nach Restore |

## Deployment-Ablauf

```
┌─────────────────────────────────────┐
│ Gate 0: Vorbereitung                │
│ (Inventory, SSH-Keys, Profil)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Gate 1: Host-Validierung            │
│ (Hosts, Inventar, Connectivity)     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Gate 2: Dry-Run und Planung         │
│ (Syntax, Dry-Run, Diff)             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Gate 3: Preflight-Checks            │
│ (OS, Speicher, Sudo, Python)        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Gate 4: QA Smoke Tests              │
│ (Status grün, Logs, Fehler)         │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Gate 5: Deployment                  │
│ (Live-Ausführung, Monitoring)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Gate 6: Post-Deployment Validierung │
│ (Services, Konfiguration)           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Gate 7: Restore-Test (Optional)     │
│ (Backup-Verifikation, Restore)      │
└─────────────────────────────────────┘
```

## Schnelle Checkliste

Vor dem Deployment:

- [ ] Gate 0: Vorbereitung abgeschlossen
- [ ] Gate 1: Host-Validierung erfolgreich
- [ ] Gate 2: Dry-Run ohne Fehler
- [ ] Gate 3: Preflight-Checks bestanden
- [ ] Gate 4: QA Smoke Tests grün
- [ ] Gate 5: Deployment-Bestätigung erhalten
- [ ] Gate 6: Post-Deployment Validierung erfolgreich

## Troubleshooting

Falls ein Gate fehlschlägt:

1. **Logs überprüfen**: `cat logs/ansible.log`
2. **Fehler analysieren**: Lesen Sie die Fehlermeldung sorgfältig
3. **Problem beheben**: Beheben Sie das identifizierte Problem
4. **Gate wiederholen**: Führen Sie das fehlgeschlagene Gate erneut aus
5. **Bei Bedarf Support**: Konsultieren Sie die README.md oder SECURITY.md

## Weitere Ressourcen

- [README.md](README.md) - Projektübersicht und Quickstart
- [SECURITY.md](SECURITY.md) - Sicherheitsrichtlinien
- [RUNBOOK_MOVE.md](RUNBOOK_MOVE.md) - Hardware-Migrations-Runbook
