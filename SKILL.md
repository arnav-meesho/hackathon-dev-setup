---
name: hackathon-dev-setup
description: >
  Bootstraps a developer's local machine for the Meesho hackathon project.
  Auto-invoke when the user asks to set up their dev environment, install
  project dependencies, configure their local machine, run the setup script,
  or mentions Docker, Node.js, Git, or Go in the context of getting started.
  Handles macOS (bash) and Windows (PowerShell) automatically.
disable-model-invocation: true
---

# Hackathon Dev Setup

This skill configures your local machine with all tools required to run the
Meesho hackathon project.

## What gets installed

| Tool            | Version  | Notes              |
|-----------------|----------|--------------------|
| Git             | latest   | Required           |
| Node.js + npm   | 24.x     | Required           |
| Docker Desktop  | latest   | Requires sudo/admin |
| Go              | 1.24+    | Optional (installed by default) |

## Port reference

| Service  | Port |
|----------|------|
| Frontend | 9080 |
| Backend  | 8090 |

## Instructions for Claude

1. **Detect the operating system.**
   - Check `uname -s` output or `$env:OS` to determine if the host is macOS or Windows.

2. **On macOS**, run:
   ```bash
   bash scripts/setup.sh
   ```

3. **On Windows**, run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
   ```

4. Do not attempt to install tools manually or run individual package manager
   commands. Always delegate to the appropriate script above.

5. After the script completes, remind the user:
   - Frontend runs on **port 9080**
   - Backend runs on **port 8090**
   - They should restart their terminal (or open a new shell) so PATH changes
     from the installers take effect.
