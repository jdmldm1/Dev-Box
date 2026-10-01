ARG UBUNTU_VERSION=22.04

FROM ubuntu:${UBUNTU_VERSION} AS base

ARG TARGETARCH=amd64
ARG GO_VERSION
ARG GOPLS_VERSION
ARG DELVE_VERSION
ARG STATICCHECK_VERSION
ARG GOIMPORTS_VERSION
ARG GOFUMPT_VERSION
ARG DOTNET_VERSION
ARG CSHARPLS_VERSION
ARG ZARF_VERSION
ARG NODE_MAJOR
ARG YQ_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get install -y --no-install-recommends \
        bash-completion \
        build-essential \
        fd-find \
        git \
        git-lfs \
        jq \
        less \
        libicu70 \
        libssl3 \
        nano \
        nodejs \
        openssh-client \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        sudo \
        tree \
        unzip \
        vim \
        wget \
        zip \
        zlib1g \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -fsSL -o /usr/local/bin/yq \
        "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}" \
    && chmod +x /usr/local/bin/yq

RUN curl -fsSL -o /tmp/go.tar.gz \
        "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm -rf /tmp/go.tar.gz \
        /usr/local/go/doc \
        /usr/local/go/test \
        /usr/local/go/api \
        /usr/local/go/blog
ENV PATH="/usr/local/go/bin:${PATH}"

RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --version "${DOTNET_VERSION}" --install-dir /usr/share/dotnet \
    && rm -f /tmp/dotnet-install.sh \
    && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet \
    && find /usr/share/dotnet -depth -type d \( \
            -iname cs -o -iname de -o -iname es -o -iname fr -o -iname it \
            -o -iname ja -o -iname ko -o -iname pl -o -iname "pt-BR" \
            -o -iname ru -o -iname tr -o -iname "zh-Hans" -o -iname "zh-Hant" \
       \) -exec rm -rf {} +
ENV DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

RUN curl -fsSL -o /usr/local/bin/zarf \
        "https://github.com/zarf-dev/zarf/releases/download/v${ZARF_VERSION}/zarf_v${ZARF_VERSION}_Linux_${TARGETARCH}" \
    && chmod +x /usr/local/bin/zarf

RUN groupadd --gid 1000 dev \
    && useradd --uid 1000 --gid dev --shell /bin/bash --create-home dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev \
    && mkdir -p /home/dev/workspace /opt/airgap /opt/defaults \
    && chown -R dev:dev /home/dev /opt/airgap /opt/defaults

COPY docker/dev/entrypoint-dev.sh /opt/airgap/entrypoint-dev.sh
RUN chmod +x /opt/airgap/entrypoint-dev.sh

USER dev
WORKDIR /home/dev
ENV HOME=/home/dev \
    GOPATH=/home/dev/go \
    GOCACHE=/home/dev/.cache/go-build \
    PATH="/home/dev/go/bin:/home/dev/.local/bin:/home/dev/.dotnet/tools:${PATH}"

RUN go install golang.org/x/tools/gopls@v${GOPLS_VERSION} \
    && go install github.com/go-delve/delve/cmd/dlv@v${DELVE_VERSION} \
    && go install honnef.co/go/tools/cmd/staticcheck@v${STATICCHECK_VERSION} \
    && go install golang.org/x/tools/cmd/goimports@v${GOIMPORTS_VERSION} \
    && go install mvdan.cc/gofumpt@v${GOFUMPT_VERSION} \
    && go clean -cache -modcache \
    && dotnet tool install --global csharp-ls --version ${CSHARPLS_VERSION} \
    && dotnet nuget locals all --clear \
    && rm -rf /home/dev/.cache /home/dev/go/pkg /home/dev/.nuget

RUN git config --global --add safe.directory /home/dev/workspace \
    && git config --global init.defaultBranch main

FROM base AS dev

LABEL org.opencontainers.image.title="airgap-dev-dev" \
      org.opencontainers.image.description="Air-gapped dev container: Go, .NET, Zarf, Git"

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD command -v go >/dev/null && command -v dotnet >/dev/null && command -v zarf >/dev/null && command -v git >/dev/null || exit 1

ENTRYPOINT ["/opt/airgap/entrypoint-dev.sh"]
CMD ["sleep", "infinity"]

FROM base AS code-server

ARG CODE_SERVER_VERSION
ARG GOLANG_EXT_VERSION
ARG CSHARP_EXT_VERSION

USER root

RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- \
        --method standalone \
        --version "${CODE_SERVER_VERSION}" \
        --prefix /usr/local

RUN set -eux; \
    mkdir -p /opt/code-server/extensions /tmp/ext; \
    curl -fsSL -o /tmp/ext/golang.vsix \
        "https://open-vsx.org/api/golang/Go/${GOLANG_EXT_VERSION}/file/golang.Go-${GOLANG_EXT_VERSION}.vsix"; \
    curl -fsSL -o /tmp/ext/csharp.vsix \
        "https://open-vsx.org/api/muhammad-sammy/csharp/linux-x64/${CSHARP_EXT_VERSION}/file/muhammad-sammy.csharp-${CSHARP_EXT_VERSION}@linux-x64.vsix"; \
    code-server --extensions-dir /opt/code-server/extensions --install-extension /tmp/ext/golang.vsix; \
    code-server --extensions-dir /opt/code-server/extensions --install-extension /tmp/ext/csharp.vsix; \
    rm -rf /tmp/ext /root/.cache /home/dev/.cache; \
    chown -R dev:dev /opt/code-server

COPY docker/dev/entrypoint-code-server.sh /opt/airgap/entrypoint-code-server.sh
RUN chmod +x /opt/airgap/entrypoint-code-server.sh
RUN mkdir -p /home/dev/.local/share/code-server/User \
    && chown -R dev:dev /home/dev/.local/share/code-server

LABEL org.opencontainers.image.title="airgap-dev-code-server" \
      org.opencontainers.image.description="Air-gapped browser IDE: code-server + Go/C# tooling"

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/healthz || exit 1

USER dev
WORKDIR /home/dev
EXPOSE 8080

ENTRYPOINT ["/opt/airgap/entrypoint-code-server.sh"]
