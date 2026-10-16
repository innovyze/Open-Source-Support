# Send Email via Outlook and SMTP

Examples of **sending HTML email from InfoAsset Manager Ruby** using:

1. **Microsoft Outlook** on the desktop (UI, user selection)  
2. **`Net::SMTP`** via InfoAsset Exchange (unattended-style, configurable query)

Both scripts are **self-contained** — copy a single `.rb` file to run it. The sample content uses **`cams_pipe_repair`** (Collection Network); replace table names, navigation, and filters for your own workflows.

| Script | Run from | Delivery |
|--------|----------|----------|
| [UI-EmailViaOutlook-Example.rb](./UI-EmailViaOutlook-Example.rb) | **Network → Run Ruby Script…** | Outlook COM (`win32ole`) |
| [IE-EmailViaSMTP-Example.rb](./IE-EmailViaSMTP-Example.rb) | **InfoAsset Exchange** | SMTP (optional) |

Optional helpers (not loaded by Ruby):

| File | Purpose |
|------|---------|
| [run_IE_EmailViaSMTP-Example.bat](./run_IE_EmailViaSMTP-Example.bat) | Runs Exchange; loads **`smtp.local.env`** when present |
| [smtp.env.example.txt](./smtp.env.example.txt) | Template for SMTP environment variables |

**Secrets:** Copy the example to **`smtp.local.env`** (listed in [`.gitignore`](./.gitignore)). Do not commit passwords or live addresses to the repo.

---

## UI example — Outlook and GeoPlan selection

Builds an HTML summary for each **selected** `cams_pipe_repair`, then creates an Outlook message (draft by default).

### Prerequisites

| Requirement | Notes |
|-------------|--------|
| InfoAsset Manager on **Windows** | UI script |
| **Collection Network** open | `WSApplication.current_network` |
| **Microsoft Outlook** installed | `Outlook.Application` |
| Selection on **`cams_pipe_repair`** | `row_object_collection_selection` |

### Usage

1. Select objects on the GeoPlan (sample: pipe repairs).  
2. **Network → Run Ruby Script…** → `UI-EmailViaOutlook-Example.rb`.  
3. Enter recipients, subject, optional InfoAsset Online host/workspace, send vs draft.

### Validation (sample rules)

- **Critical** (stops run): US node X/Y, pipe width.  
- **Important** (Yes/No per record, includes ID): other configured fields.  
- Records with no related **pipe** are skipped.

---

## Exchange example — SMTP and query-based selection

Opens a **Collection Network** by ID, collects **`cams_pipe_repair`** rows where **`completed` is not true**, builds HTML, then:

| Mode | Behaviour |
|------|-----------|
| **`DRY_RUN = true`** (default) | Writes **`OUTPUT_HTML_PATH`** only |
| **`DRY_RUN = false`** + **`SEND_VIA_SMTP = true`** | Sends via SMTP (`IAM_SMTP_*` / `smtp.local.env`) |

Edit the configuration block at the top of `IE-EmailViaSMTP-Example.rb`:

| Setting | Purpose |
|---------|---------|
| `COLLECTION_NETWORK_ID` | Network ID (as in other IE examples) |
| `RECIPIENT_EMAILS` | To: addresses |
| `IMPORTANT_MISSING_POLICY` | `:skip` or `:include` |
| `CRITICAL_MISSING_POLICY` | `:skip` or `:abort` |
| `DRY_RUN` / `SEND_VIA_SMTP` | Output vs send |
| `SMTP_HOST`, `SMTP_FROM`, `SMTP_USER` | Optional in-script; password only in env |

If SMTP is not configured, the script **still saves HTML** and prints what to set (no uncaught `RuntimeError`). InfoAsset Exchange treats Ruby **`exit`** as failure; this script **`return`**s from a wrapper so successful runs end with **`Script finished.`**

### Exchange usage

1. Set `COLLECTION_NETWORK_ID` and policies; run with **`DRY_RUN = true`**.  
2. Copy **`smtp.env.example.txt`** → **`smtp.local.env`**, set **`IAM_SMTP_PASSWORD`**.  
3. Run [run_IE_EmailViaSMTP-Example.bat](./run_IE_EmailViaSMTP-Example.bat) (edit **`IEXCHANGE`** path) or:

```bat
"C:\Program Files\Autodesk\InfoAsset Manager 2026\iexchange.exe" "C:\path\to\IE-EmailViaSMTP-Example.rb" /ADSKASSET
```

4. For live send: **`DRY_RUN = false`**, **`SEND_VIA_SMTP = true`**. Remove **`pause`** from the `.bat` for Task Scheduler.

### SMTP environment variables

| Variable | When required | Notes |
|----------|----------------|--------|
| `IAM_SMTP_HOST` | Send | Relay hostname (or `SMTP_HOST` in script) |
| `IAM_SMTP_FROM` | Send | Allowed sender |
| `IAM_SMTP_PASSWORD` | Auth relay | Never put in `.rb` source |
| `IAM_SMTP_USER` | Auth relay | Optional if relay uses IP trust |
| `IAM_SMTP_PORT` | No | Default `587` |
| `IAM_SMTP_STARTTLS` | No | Default on |

Uses Ruby **`Net::SMTP`** with **`enable_starttls_auto`** when STARTTLS is enabled.

---

## Adapting for other objects

| Area | Sample in script | Change to |
|------|------------------|-----------|
| Table | `cams_pipe_repair` | Your table |
| UI selection | `row_object_collection_selection` | Same API, your table |
| IE query | `completed` not true | Your filter (field values, flags, dates) |
| HTML body | Pipe / property fields | Your attributes and links |
| IAO links | Optional server + workspace | [0047](../0047%20Create%20InfoAsset%20Online%20URL%20Hyperlinks/Readme.md) URL pattern |

The UI and IE files **duplicate** helper logic so each stays copy-paste friendly; update both if you want matching behaviour.

---

## Related examples

- [0047 Create InfoAsset Online URL Hyperlinks](../0047%20Create%20InfoAsset%20Online%20URL%20Hyperlinks/Readme.md)  
- [0016 Copy CCTV defect images to pipe repair](../0016%20Update%20objects%20through%20relationships%20or%20comparison/UI-CopyCCTVDefectImagesToPipeRepair.rb) — sample `cams_pipe_repair` workflow
