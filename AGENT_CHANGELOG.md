# AGENT_CHANGELOG.md - The Solid Base

Dieses Changelog dokumentiert die Änderungen, die im Rahmen der "The Solid Base"-Phase durchgeführt wurden, um das Projekt zu stabilisieren und wartbarer zu machen.

## v2.1.0 - The Solid Base (2024-07-29)

### ✨ Neue Features & Verbesserungen

- **Intelligente Hostname-Logik**: Die `system_setup`-Rolle bricht nicht mehr ab, wenn der Hostname nicht übereinstimmt. Stattdessen wird der Hostname automatisch korrigiert und ein Reboot geplant.
- **Intelligente VM-Spec-Validierung**: Die `provision_guests`-Rolle überspringt existierende VMs nicht mehr blind. Sie prüft nun die CPU- und RAM-Spezifikationen und passt sie bei Bedarf an.
- **Storage-Architektur**: Eine neue `storage_setup`-Rolle wurde hinzugefügt, um Disk 2 (`/dev/sdb`) zu formatieren und unter `/mnt/data_storage` zu mounten. Dies trennt System- und Massendaten.
- **Ansible Vault Integration**: Das Projekt ist nun für die Verwendung von Ansible Vault vorbereitet. Eine `vault.yml.example`-Datei dient als Vorlage für die sichere Speicherung von Secrets.

### 🧹 Projektbereinigung (Declutter)

- **`heimnetz-dashboard` deaktiviert**: Das veraltete `heimnetz-dashboard` wurde deaktiviert. Das Template wurde nach `templates/docker-compose/_disabled/` verschoben und aus der `apps_config` sowie den `deployment_profiles` entfernt.

### 🔒 Sicherheitsverbesserungen

- **Firewall-Logik**: Die Aktivierung der PVE-Firewall wurde ans Ende des Haupt-Playbooks (`site.yml`) verschoben, um Verbindungsabbrüche während des Setups zu verhindern.
- **Vault-Struktur**: Eine `vault.yml` wurde für die Speicherung von Passwörtern und Tokens angelegt und in `.gitignore` aufgenommen.

### 🐛 Bugfixes

- **Keine**

### 📚 Dokumentation

- **`AGENT_CHANGELOG.md`**: Dieses Changelog wurde erstellt.
- **`README.md`**: Die Dokumentation wurde aktualisiert, um die neuen Features und die stabilisierte Architektur widerzuspiegeln.
- **`storage_setup/README.md`**: Eine detaillierte Dokumentation für die neue Storage-Rolle wurde hinzugefügt.

## Zusammenfassung der Änderungen

| Feature / Änderung | Beschreibung | Status |
| :--- | :--- | :--- |
| **Projektbereinigung** | Veraltete Templates und Konfigurationen deaktiviert | ✅ Fertig |
| **Sicherheitsmechanismen** | Vault-Integration und Firewall-Logik verbessert | ✅ Fertig |
| **Storage-Architektur** | Disk 2 Formatierung und Mounting implementiert | ✅ Fertig |
| **Wartbarkeit** | Intelligente Hostname- und VM-Spec-Logik hinzugefügt | ✅ Fertig |
| **Dokumentation** | Alle Änderungen dokumentiert und READMEs aktualisiert | ✅ Fertig |

Das Projekt ist nun deutlich stabiler, sicherer und wartbarer. Die "Solid Base" ist gelegt, um zukünftige Features wie das Plugin-System, WireGuard-Tunneling und GPU-Passthrough modular und sicher zu implementieren.
