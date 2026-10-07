# Dev-Box

Air-gapped dev environment in a single image (Azure Linux 3.0), shipped as a Zarf package or a Compose tar bundle.

**Included:** code-server (port `8080`) with Go and C# extensions, Go (`dlv`, `gopls`, `staticcheck`, `goimports`, `gofumpt`), .NET SDK (`csharp-ls`), Zarf, `git`, `gcc`/`make`, `curl`, `tcpdump`, `ssh`, `vi`.

## Zarf

Deploys the Helm chart in `charts/dev-box` to a Zarf-initialized cluster (namespace `dev-box`).

```bash
cp .env.example .env
docker compose build                          # builds airgap-dev:local
zarf package create . --confirm
zarf package deploy zarf-package-dev-box-amd64-1.4.1.tar.zst --confirm --set CODE_SERVER_PASSWORD=<password>
# Service is a NodePort on 30080. Kind does not publish it by default; either add an extraPortMappings entry for 30080 to the kind config or run:
# docker run -d --name dev-box-proxy --restart unless-stopped --network kind -p 127.0.0.1:8080:8080 alpine/socat tcp-listen:8080,fork,reuseaddr tcp:<kind-node-container>:30080
# then open http://localhost:8080
```

Workspace and code-server data live in PVCs. The chart can also be used directly: `helm install dev-box charts/dev-box -n dev-box --create-namespace --set password=<password>`.

## Compose

```bash
cp .env.example .env
./scripts/prepare-online.sh && ./scripts/export-offline.sh    # online: builds offline/airgap-dev-offline-bundle.tar.gz
./scripts/import-offline.sh <bundle.tar.gz> && ./scripts/start.sh    # air-gapped
```

PowerShell equivalents are in `scripts/*.ps1`. Open `http://localhost:8080` and log in with `CODE_SERVER_PASSWORD`. Projects go in `./workspace`; `./dev` opens a shell in the container.
