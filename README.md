<div align="center">

# 🛡️ LogRhythm SIEM — Enterprise Deployment & Administration Lab

**Secure · Detect · Respond · Monitor**

[![LogRhythm](https://img.shields.io/badge/LogRhythm-SIEM-4A90D9?style=flat-square)](https://logrhythm.com)
[![Grafana](https://img.shields.io/badge/Grafana-Observability-F46800?style=flat-square&logo=grafana&logoColor=white)](https://grafana.com)
[![PowerShell](https://img.shields.io/badge/PowerShell-Scripting-5391FE?style=flat-square&logo=powershell&logoColor=white)](https://docs.microsoft.com/en-us/powershell/)
[![MITRE ATT&CK](https://img.shields.io/badge/MITRE_ATT%26CK-Mapped-E3001B?style=flat-square)](https://attack.mitre.org)
[![Windows Server](https://img.shields.io/badge/Windows_Server-Infrastructure-0078D4?style=flat-square&logo=windows&logoColor=white)](https://www.microsoft.com/en-us/windows-server)

---

*Internship project at* **DATAPROTECT, Casablanca** — *February to April 2026*
*Supervisor: M. Modibo MALLÉ*

</div>

---

## 📖 About

This repository documents a complete, hands-on deployment of a **LogRhythm SIEM** platform — from bare-metal installation through custom log ingestion, AI Engine alarm creation, File Integrity Monitoring (FIM), and full platform health observability via Grafana.

The project covers the full SIEM lifecycle:
- Multi-component platform installation and configuration
- Custom log source integration in CSV and JSON formats with MPE parsing rules
- AI Engine detection rules mapped to MITRE ATT&CK techniques
- File Integrity Monitoring for add / modify / delete events
- PowerShell scripts to simulate realistic security events for end-to-end testing
- Platform health monitoring via Grafana dashboards

---

## 🏗️ Architecture

### LogRhythm Platform — Official Architecture

The diagram below shows the standard LogRhythm SIEM component topology and data flow, as deployed in this project:

<div align="center">

![LogRhythm Architecture](screenshots/architecture/logrhythm_architecture.png)

</div>

| Component | Role |
|---|---|
| **Hosts / Networks** | Log sources — system, security, audit, application, network & firewall logs |
| **System Monitors** | Endpoint agents for file, process, connection, and DLP monitoring |
| **Data Processor** | Central ingestion hub — normalizes raw logs to structured CEF format |
| **AI Engine** | Correlates events and fires alarms based on detection rules |
| **Platform Manager** | Management console — RBAC, deployment, Web Console access |
| **Indexer Cluster** | Stores raw and structured logs, enables forensic search |
| **Client / Web Console** | SOC analyst interface — alarm triage, log search, case management |

---

### Lab-Specific Architecture — What We Built

The diagram below maps the exact topology of this lab to the official architecture above — showing both machines, custom log sources, PowerShell simulation scripts, and each detection rule with its MITRE technique:
![Lab-Specific Architecture](screenshots/architecture/logrhythm_architecture.svg)
---

## 📋 Table of Contents

1. [Phase 1 — Installation & Initial Setup](#phase-1--installation--initial-setup)
2. [Phase 2 — Component Configuration](#phase-2--component-configuration)
3. [Phase 3 — Custom Log Sources](#phase-3--custom-log-sources)
4. [Phase 4 — AI Engine Alarms](#phase-4--ai-engine-alarms)
5. [Phase 5 — File Integrity Monitoring](#phase-5--file-integrity-monitoring-fim)
6. [Phase 6 — Platform Health & Grafana](#phase-6--platform-health--grafana-observability)
7. [Log Generation Scripts](#log-generation-scripts)
8. [Key Takeaways](#key-takeaways)

---

## Phase 1 — Installation & Initial Setup

### Components Installed

| Component | Role |
|---|---|
| Platform Manager | Central management console & web UI |
| Data Processor | Log ingestion & MPE normalization engine |
| AI Engine | Real-time correlation & detection |
| System Monitor | Health monitoring & FIM agent |
| Data Indexer | Log storage & search |

### Key Technical Challenges

- **Resource planning** — High CPU/RAM demands required upfront capacity modeling
- **Inter-component networking** — Configuring secure channels between Platform Manager, Data Processor, and AI Engine
- **Certificate management** — Setting up SSL/TLS for all component communications
- **Dependency resolution** — Handling prerequisite software and version compatibility

### Screenshots

> 📸 `screenshots/01-installation/`
>
> | File | Content |
> |---|---|
> | `01_platform_manager_install.png` | Platform Manager installer / initial boot |
> | `02_data_processor_install.png` | Data Processor setup |
> | `03_ai_engine_install.png` | AI Engine installation |
> | `04_system_monitor_install.png` | System Monitor agent setup |
> | `05_services_running.png` | All services confirmed running |
> | `06_web_console_login.png` | First successful login to the Web Console |

---

## Phase 2 — Component Configuration

After installation, each component was configured and integrated:

- **Platform Manager** — Configured entity hierarchy, user roles (RBAC), and deployment policies
- **Data Processor** — Set log ingestion pipelines and retention policies
- **AI Engine** — Linked to Data Processor for real-time event correlation
- **System Monitor** — Deployed to `TARGET_MACHINE` for health checks and FIM

### Screenshots

> 📸 `screenshots/02-configuration/`
>
> | File | Content |
> |---|---|
> | `01_platform_manager_dashboard.png` | Platform Manager home / deployment manager |
> | `02_entity_structure.png` | Entity/site hierarchy |
> | `03_data_processor_config.png` | Data Processor pipeline settings |
> | `04_ai_engine_config.png` | AI Engine configuration panel |
> | `05_system_monitor_agent.png` | Agent connected on TARGET_MACHINE |
> | `06_rbac_roles.png` | User roles and permissions |

---

## Phase 3 — Custom Log Sources

Two custom log source types were created in the Deployment Manager, each with tailored **MPE (Message Processing Engine)** parsing rules to extract fields and normalize to LogRhythm's Common Event Format (CEF).

---

### 3.1 Auth Logs — CSV Format

**File:** `C:\LogRhythmLogs\auth_logs.csv` | **Script:** `Generate-EnrichedAuthLogs.ps1`

```csv
timestamp,source_ip,username,event_type,status,hostname
2026-04-23T10:26:00,192.168.1.50,jdoe,SSH_LOGIN,FAILED,TARGET_MACHINE
```

**MPE rule highlights:**
- Delimiter: comma (`,`)
- Fields extracted: `timestamp`, `source_ip`, `username`, `event_type`, `status`
- Classification: **Authentication → Failed Login**

### 3.2 Firewall Logs — JSON Format

**File:** `C:\LogRhythmLogs\firewall_logs.json` | **Script:** `Generate-FirewallLogs-JSON-FIXED.ps1`

```json
{
  "timestamp": "2026-04-20T15:50:00Z",
  "src_ip": "10.0.0.5",
  "dst_ip": "8.8.8.8",
  "action": "DENY",
  "protocol": "TCP",
  "dst_port": 443
}
```

**MPE rule highlights:**
- Format: JSON key-value extraction
- Fields: `timestamp`, `src_ip`, `dst_ip`, `action`, `protocol`, `dst_port`
- Classification: **Network → Firewall Activity**

### Screenshots

> 📸 `screenshots/03-log-sources/`
>
> | File | Content |
> |---|---|
> | `csv/01_log_source_type_csv.png` | CSV Log Source Type definition |
> | `csv/02_mpe_rule_csv.png` | MPE Rule editor — CSV parsing |
> | `csv/03_field_mapping_csv.png` | Field mapping to CEF |
> | `csv/04_parsed_events_csv.png` | Parsed auth events in Log Search |
> | `json/01_log_source_type_json.png` | JSON Log Source Type definition |
> | `json/02_mpe_rule_json.png` | MPE Rule editor — JSON parsing |
> | `json/03_parsed_events_json.png` | Firewall events in Log Search |
> | `scripts_folder.png` | All scripts in `C:\LogRhythmLogs\` |

---

## Phase 4 — AI Engine Alarms

Two detection rules were built in the AI Engine, mapped to the **MITRE ATT&CK** framework.

---

### 🔴 Alarm 1 — Brute Force Detection

| Parameter | Value |
|---|---|
| Trigger | ≥ 5 failed auth events from same source IP within 10 min |
| Log Sources | `auth_logs.csv` |
| MITRE ATT&CK | [T1110 — Brute Force](https://attack.mitre.org/techniques/T1110/) |
| Priority | High |
| Risk Rating | 75 / 100 |
| Response | Email to SOC · Auto-case creation |

**Rule logic:**
1. Filter: `event_type = FAILED_LOGIN`
2. Aggregate by `source_ip`
3. Count within a 10-minute sliding window
4. Fire alarm when count ≥ 5

### 🟠 Alarm 2 — After-Hours File Access

| Parameter | Value |
|---|---|
| Trigger | Sensitive file access outside 08:00–18:00 |
| Log Sources | FIM events + file access logs |
| MITRE ATT&CK | [T1005 — Data from Local System](https://attack.mitre.org/techniques/T1005/) |
| Priority | Medium-High |
| Risk Rating | 65 / 100 |
| Response | Email notification · Audit log entry |

### Screenshots

> 📸 `screenshots/04-alarms/`
>
> | File | Content |
> |---|---|
> | `brute-force/01_aie_rule_editor.png` | AI Engine rule editor — brute force |
> | `brute-force/02_threshold_config.png` | Threshold and time-window settings |
> | `brute-force/03_alarm_triggered.png` | Alarm in Alarm Manager |
> | `brute-force/04_case_created.png` | Auto-created investigation case |
> | `after-hours/01_aie_rule_time_filter.png` | Time-based filter configuration |
> | `after-hours/02_alarm_triggered.png` | After-hours alarm fired |

---

## Phase 5 — File Integrity Monitoring (FIM)

FIM was configured to detect unauthorized changes inside a monitored directory on `TARGET_MACHINE`. Any file or folder change triggers an alarm in the AI Engine.

### Monitored Path

```
C:\FIM_TEST\
```

### Detection Coverage

| Change Type | Alarm |
|---|---|
| File / folder **added** | ✅ Triggered |
| File / folder **modified** | ✅ Triggered |
| File / folder **deleted** | ✅ Triggered |

### Technical Challenges Solved

- **Case sensitivity** — LogRhythm FIM path filters are case-sensitive; resolved by testing both casing variants
- **AND/OR logic in Rule Blocks** — Mastered filter logic to match add/modify/delete events independently
- **Regex path matching** — Developed patterns for flexible directory matching (e.g., `C:\\FIM_TEST\\.*`)
- **Baseline management** — Documented initial file states before enabling live monitoring

### Screenshots

> 📸 `screenshots/05-fim/`
>
> | File | Content |
> |---|---|
> | `01_fim_policy.png` | FIM policy — monitored path setup |
> | `02_rule_block_add.png` | Rule Block for ADD events |
> | `03_rule_block_modify.png` | Rule Block for MODIFY events |
> | `04_rule_block_delete.png` | Rule Block for DELETE events |
> | `05_fim_alarm_add.png` | FIM alarm — file created in `C:\FIM_TEST\` |
> | `06_fim_alarm_modify.png` | FIM alarm — file modified |
> | `07_fim_alarm_delete.png` | FIM alarm — file deleted |
> | `08_fim_test_folder.png` | `FIM_TEST` folder in Explorer sidebar |

---

## Phase 6 — Platform Health & Grafana Observability

Platform health was monitored through LogRhythm's built-in health views and a **Grafana** dashboard connected to platform metrics.

### Health Checks Performed

- **System Monitor** — Component status across all platform nodes
- **Data Processor** — Events per second (EPS) throughput and queue depth
- **AI Engine** — Processing latency and rule evaluation rate
- **Data Indexer** — Storage utilization and index health
- **Log Sources** — Connectivity status for all custom sources

### Screenshots

> 📸 `screenshots/06-health-grafana/`
>
> | File | Content |
> |---|---|
> | `01_system_monitor_health.png` | System Monitor component health |
> | `02_data_processor_eps.png` | Events per second throughput |
> | `03_ai_engine_status.png` | AI Engine processing status |
> | `04_grafana_overview.png` | Grafana main dashboard |
> | `05_grafana_log_volume.png` | Log ingestion volume over time |
> | `06_grafana_alarm_rate.png` | Alarm firing rate panel |

---

## Log Generation Scripts

All scripts live in `C:\LogRhythmLogs\` on `TARGET_MACHINE` and simulate realistic security events for end-to-end testing.

| Script | Purpose |
|---|---|
| `Generate-EnrichedAuthLogs.ps1` | Generates CSV auth logs — failed/success logins, IPs, users |
| `Generate-FirewallLogs-JSON.ps1` | Generates JSON firewall allow/deny events |
| `Generate-FirewallLogs-JSON-FIXED.ps1` | Fixed version with corrected timestamp formatting |
| `Generate-FIM-Activity.ps1` | Simulates file add/modify/delete in `C:\FIM_TEST\` |
| `Test-LogRhythmAlarms.ps1` | End-to-end test targeting both AI Engine alarms |
| `Lancer-GenerateurLogs-Enrichi.bat` | Batch launcher — quick-start wrapper |

---

## Key Takeaways

### Security Use Cases Demonstrated

| Use Case | Detection Method | MITRE ATT&CK |
|---|---|---|
| Brute force / credential stuffing | Threshold correlation on auth failures | [T1110](https://attack.mitre.org/techniques/T1110/) |
| After-hours data access | Time-based AI Engine rule | [T1005](https://attack.mitre.org/techniques/T1005/) |
| Unauthorized file system changes | FIM agent + AI Engine alarm | [T1565](https://attack.mitre.org/techniques/T1565/) |

### Lessons Learned

- **MPE Rules** are the backbone of LogRhythm's power — getting parsing right for non-standard formats (especially JSON) requires iterative testing
- **AI Engine rule logic** is nuanced: block ordering and AND/OR conditions significantly affect detection accuracy
- **FIM is sensitive to path casing and regex escaping** — small mistakes lead to silent failures
- **Grafana integration** transforms raw component metrics into operational insight

---

## 📁 Repository Structure

```
LogRhythm-SIEM-Lab/
├── README.md
├── scripts/
│   ├── Generate-EnrichedAuthLogs.ps1
│   ├── Generate-FirewallLogs-JSON-FIXED.ps1
│   ├── Generate-FIM-Activity.ps1
│   ├── Test-LogRhythmAlarms.ps1
│   └── Lancer-GenerateurLogs-Enrichi.bat
├── sample-logs/
│   ├── auth_logs_enriched_example.csv
│   └── firewall_logs_sample.json
├── config/
│   ├── Configuration_LogRhythm_CSV_Enrichi.txt
│   └── Configuration_CSV_Enrichi_LogRhythm.docx
└── screenshots/
    ├── architecture/
    │   └── logrhythm_architecture.png
    ├── 01-installation/
    ├── 02-configuration/
    ├── 03-log-sources/
    │   ├── csv/
    │   └── json/
    ├── 04-alarms/
    │   ├── brute-force/
    │   └── after-hours/
    ├── 05-fim/
    └── 06-health-grafana/
```

---

## 🔗 Connect

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Mahamadou_Dansoko-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://linkedin.com/in/tjodansoko)
[![GitHub](https://img.shields.io/badge/GitHub-mahamadoudansoko-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/mahamadoudansoko)

---

<div align="center">
<i>"Security and automation go hand in hand — a connected world must also be a protected and resilient one."</i><br>
— Mahamadou Dansoko
</div>