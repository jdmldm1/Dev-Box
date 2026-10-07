# Dev-Box

Air-gapped dev environment in a single image (Azure Linux 3.0), shipped as a Zarf package or a Compose tar bundle.

**Included:** code-server (port `8080`) with Go and C# extensions, Go (`dlv`, `gopls`, `staticcheck`, `goimports`, `gofumpt`), .NET SDK (`csharp-ls`), Zarf, `git`, `gcc`/`make`, `curl`, `tcpdump`, `ssh`, `vi`.

## Zarf

```bash
cp .env.example .env
docker compose build
zarf package create . --confirm
```

## Compose

```bash
cp .env.example .env
./scripts/prepare-online.sh && ./scripts/export-offline.sh    # online: builds offline/airgap-dev-offline-bundle.tar.gz
./scripts/import-offline.sh <bundle.tar.gz> && ./scripts/start.sh    # air-gapped
```

PowerShell equivalents are in `scripts/*.ps1`. Open `http://localhost:8080` and log in with `CODE_SERVER_PASSWORD`. Projects go in `./workspace`; `./dev` opens a shell in the container.
