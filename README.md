# Dev-Box

Containerized dev environment for air-gapped environment, bundleable in the form of
- Compose stack
- Zarf package 

## Zarf 

```bash
zarf package create . --confirm                   
```

## Compose 

1. On a machine with internet access:
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

2. Transfer the archive and its `.sha256` across the gap.

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

## Tools

- **Go** — `./dev go version`; code-server's Go extension uses the baked-in gopls/dlv/staticcheck.
- **.NET** — `./dev dotnet new console -o /home/dev/workspace/hello`; C# extension bundles Roslyn +
  netcoredbg, no runtime download.
- **Zarf** — `./dev zarf version`. No network at runtime; build packages on a connected machine and
  transfer like the offline bundle.
