ARG AZURELINUX_VERSION=3.0

# ---------------------------------------------------------------------------
# Stage "go": base OS, Go toolchain + dev tools, Zarf, code-server + Go ext.
# Build with --target go for the smaller Go-only image.
# ---------------------------------------------------------------------------
FROM mcr.microsoft.com/azurelinux/base/core:${AZURELINUX_VERSION} AS go

ARG TARGETARCH=amd64
ARG GO_VERSION
ARG GOPLS_VERSION
ARG DELVE_VERSION
ARG STATICCHECK_VERSION
ARG GOIMPORTS_VERSION
ARG GOFUMPT_VERSION
ARG ZARF_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC

RUN tdnf install -y \
        binutils \
        ca-certificates \
        curl \
        gcc \
        gcc-c++ \
        git \
        glibc-devel \
        gzip \
        icu \
        kernel-headers \
        less \
        make \
        openssh-clients \
        openssl-libs \
        shadow-utils \
        sudo \
        tar \
        tcpdump \
        unzip \
        vim-minimal \
        zlib \
    && tdnf clean all \
    && rm -rf /var/cache/tdnf /tmp/* /var/tmp/* /usr/share/doc /usr/share/man /usr/share/info

RUN curl -fsSL -o /tmp/go.tar.gz \
        "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm -rf /tmp/go.tar.gz \
        /usr/local/go/doc \
        /usr/local/go/test \
        /usr/local/go/api \
        /usr/local/go/blog
ENV PATH="/usr/local/go/bin:${PATH}"

RUN curl -fsSL -o /usr/local/bin/zarf \
        "https://github.com/zarf-dev/zarf/releases/download/v${ZARF_VERSION}/zarf_v${ZARF_VERSION}_Linux_${TARGETARCH}" \
    && chmod +x /usr/local/bin/zarf

RUN groupadd --gid 1000 dev \
    && useradd --uid 1000 --gid dev --shell /bin/bash --create-home dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev \
    && mkdir -p /home/dev/workspace /opt/airgap /opt/defaults \
    && chown -R dev:dev /home/dev /opt/airgap /opt/defaults

USER dev
WORKDIR /home/dev
ENV HOME=/home/dev \
    GOPATH=/home/dev/go \
    GOCACHE=/home/dev/.cache/go-build \
    PATH="/home/dev/go/bin:/home/dev/.local/bin:/home/dev/.dotnet/tools:${PATH}"

# -s -w strips symbol/debug tables from the tool binaries themselves (dlv still
# reads debug info from the programs it debugs, so debugging is unaffected)
RUN go install -trimpath -ldflags "-s -w" golang.org/x/tools/gopls@v${GOPLS_VERSION} \
    && go install -trimpath -ldflags "-s -w" github.com/go-delve/delve/cmd/dlv@v${DELVE_VERSION} \
    && go install -trimpath -ldflags "-s -w" honnef.co/go/tools/cmd/staticcheck@v${STATICCHECK_VERSION} \
    && go install -trimpath -ldflags "-s -w" golang.org/x/tools/cmd/goimports@v${GOIMPORTS_VERSION} \
    && go install -trimpath -ldflags "-s -w" mvdan.cc/gofumpt@v${GOFUMPT_VERSION} \
    && go clean -cache -modcache \
    && rm -rf /home/dev/.cache /home/dev/go/pkg

RUN git config --global --add safe.directory /home/dev/workspace \
    && git config --global init.defaultBranch main

ARG CODE_SERVER_VERSION
ARG GOLANG_EXT_VERSION

USER root

RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- \
        --method standalone \
        --version "${CODE_SERVER_VERSION}" \
        --prefix /usr/local \
    # Cloud-only components are dead weight in an air gap: the bundled Copilot
    # extension, its language-server SDK, and Microsoft eXecution Containers.
    && rm -rf \
        "/usr/local/lib/code-server-${CODE_SERVER_VERSION}/lib/vscode/extensions/copilot" \
        "/usr/local/lib/code-server-${CODE_SERVER_VERSION}/lib/vscode/node_modules/@github/copilot-sdk" \
        "/usr/local/lib/code-server-${CODE_SERVER_VERSION}/lib/vscode/node_modules/@github/copilot-sdk-linux-x64" \
        "/usr/local/lib/code-server-${CODE_SERVER_VERSION}/lib/vscode/node_modules/@microsoft/mxc-sdk"

RUN set -eux; \
    mkdir -p /opt/code-server/extensions /tmp/ext; \
    curl -fsSL -o /tmp/ext/golang.vsix \
        "https://open-vsx.org/api/golang/Go/${GOLANG_EXT_VERSION}/file/golang.Go-${GOLANG_EXT_VERSION}.vsix"; \
    code-server --extensions-dir /opt/code-server/extensions --install-extension /tmp/ext/golang.vsix; \
    rm -rf /tmp/ext /root/.cache /home/dev/.cache; \
    chown -R dev:dev /opt/code-server

COPY docker/dev/entrypoint.sh /opt/airgap/entrypoint.sh
RUN chmod +x /opt/airgap/entrypoint.sh
RUN mkdir -p /home/dev/.local/share/code-server/User \
    && chown -R dev:dev /home/dev/.local/share/code-server

LABEL org.opencontainers.image.title="airgap-dev" \
      org.opencontainers.image.description="Air-gapped dev box: code-server, Go, Zarf, tcpdump"

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/healthz || exit 1

USER dev
WORKDIR /home/dev
EXPOSE 8080

ENTRYPOINT ["/opt/airgap/entrypoint.sh"]

# ---------------------------------------------------------------------------
# Stage "full" (default): adds the .NET SDK, csharp-ls, and the C# extension.
# ---------------------------------------------------------------------------
FROM go AS full

ARG DOTNET_VERSION
ARG CSHARPLS_VERSION
ARG CSHARP_EXT_VERSION

USER root

RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --version "${DOTNET_VERSION}" --install-dir /usr/share/dotnet \
    && rm -f /tmp/dotnet-install.sh \
    && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet \
    # Trim localized satellite assemblies by file pattern. Matching locale
    # directories by name (-iname cs, ...) is wrong: it also deletes
    # Sdks/Microsoft.NET.Sdk/codestyle/cs, which MSBuild imports, breaking
    # every C# build with MSB4019.
    && find /usr/share/dotnet -name '*.resources.dll' -delete \
    && find /usr/share/dotnet -depth -type d -empty -delete
ENV DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

USER dev

RUN dotnet tool install --global csharp-ls --version ${CSHARPLS_VERSION} \
    && dotnet nuget locals all --clear \
    && rm -rf /home/dev/.cache /home/dev/.nuget

USER root

RUN set -eux; \
    mkdir -p /tmp/ext; \
    curl -fsSL -o /tmp/ext/csharp.vsix \
        "https://open-vsx.org/api/muhammad-sammy/csharp/linux-x64/${CSHARP_EXT_VERSION}/file/muhammad-sammy.csharp-${CSHARP_EXT_VERSION}@linux-x64.vsix"; \
    code-server --extensions-dir /opt/code-server/extensions --install-extension /tmp/ext/csharp.vsix; \
    rm -rf /tmp/ext /root/.cache /home/dev/.cache; \
    chown -R dev:dev /opt/code-server

LABEL org.opencontainers.image.description="Air-gapped dev box: code-server, Go, .NET, Zarf, tcpdump"

USER dev
WORKDIR /home/dev
