# system_setup Role

Diese Rolle führt die grundlegende Systemkonfiguration durch.

## Aufgaben

- Paket-Manager aktualisieren
- Erforderliche Pakete installieren
- Zeitzone setzen
- Locale konfigurieren
- Hostname setzen
- Firewall konfigurieren (optional)
- Log-Verzeichnis erstellen

## Variablen

| Variable | Default | Beschreibung |
|----------|---------|-------------|
| `system_setup_packages` | Siehe defaults/main.yml | Liste der zu installierenden Pakete |
| `system_timezone` | UTC | Systemzeitzone |
| `system_locale` | en_US.UTF-8 | System-Locale |
| `enable_firewall` | true | Firewall aktivieren |
| `ssh_port` | 22 | SSH-Port |
| `log_dir` | /var/log/novachris_home | Log-Verzeichnis |

## Tags

- `system_setup`: Alle Tasks dieser Rolle
- `packages`: Paket-Installation
- `configuration`: Konfiguration
- `firewall`: Firewall-Konfiguration
- `logging`: Logging-Konfiguration
