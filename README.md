# Dev-Box

Containerized dev environment for air-gapped environment, bundleable in the form of
- Compose stack (tar bundle)
- Zarf package 

## Zarf 

```bash
zarf package create . --confirm                   
```

## Compose 

1. 
   ```bash
   cp .env.example .env
   ./scripts/prepare-online.sh
   ./scripts/export-offline.sh
   ```
   ```powershell
   Copy-Item .env.example .env
   .\scripts\prepare-online.ps1
   .\scripts\export-offline.ps1
   ```
   Produces `offline/airgap-dev-offline-bundle.tar.gz` + `.sha256`.

2. Transfer the archive and its `.sha256` to offline machine 

3. On the air-gapped machine (Docker installed there too):
   ```bash
   ./scripts/import-offline.sh /path/to/airgap-dev-offline-bundle.tar.gz
   ./scripts/start.sh         
   ```
   ```powershell
   .\scripts\import-offline.ps1 C:\path\to\airgap-dev-offline-bundle.tar.gz
   .\scripts\start.ps1         
   ```

4. Open `http://localhost:8080`, log in with `CODE_SERVER_PASSWORD`. Projects go in `./workspace`.

Other commands: `./scripts/stop.sh` (keeps volumes), `--remove-volumes`, `./scripts/status.sh`.

## Included Tools

### IDE & Interfaces
- **code-server** — Web browser-based VS Code IDE (accessible on port `8080`).
- **Extensions** — Go  and C# extensions

### Languages & Runtimes
- **Go** — Golang SDK 
- **.NET SDK** — .NET CLI and runtime 
- **Node.js & npm** — Node.js runtime and npm package manager.
- **Python 3** — Python 3 with `pip` 

### Language Tooling & Debuggers
- **Go Tools**:
  - `dlv` — Delve debugger
  - `staticcheck` — Advanced static analysis and linter
  - `gofumpt` — Stricter Go code formatter
- **C# / .NET Tools**:
  - `csharp-ls` — C# Language Server
  - Roslyn compiler and language tooling

### Packaging & Air-Gap Tools
- **Zarf** 
- **Periscope Airgap Lite**

### CLI Utilities & System Packages
- **Data & Config Processing**: `jq`, `yq`
- **Code Search & Navigation**: `ripgrep` (`rg`), `fd-find` (`fd`), `tree`
- **Version Control**: `git`, `git-lfs`
- **Build Tools**: `build-essential` (`gcc`, `g++`, `make`)
- **Transfer & Archive**: `curl`, `wget`, `openssh-client`, `zip`, `unzip`, `tar`
- **Terminal Editors & Pagers**: `vim`, `nano`, `less`
