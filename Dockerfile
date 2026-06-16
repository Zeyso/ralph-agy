FROM ubuntu:24.04

LABEL maintainer="ralph-agy"
LABEL description="Ralph autonomous AI agent loop with Google Antigravity CLI (agy)"

# Avoid interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    bash \
    screen \
    ca-certificates \
    gnupg \
    lsb-release \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Install Google Antigravity CLI (agy)
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

# Make sure agy is in PATH (installer puts it in ~/.local/bin or /usr/local/bin)
ENV PATH="/root/.local/bin:/root/bin:${PATH}"

# Verify agy is installed
RUN agy --version || echo "agy installed, version check may require auth"

# Set working directory
WORKDIR /workspace

# Copy ralph files
COPY scripts/ralph/ralph.sh /usr/local/bin/ralph.sh
RUN chmod +x /usr/local/bin/ralph.sh

COPY scripts/ralph/CLAUDE.md /workspace/CLAUDE.md
COPY scripts/ralph/prompt.md  /workspace/prompt.md

# Copy agy-specific prompt template
COPY scripts/ralph/agy-prompt.md /workspace/agy-prompt.md

# Create directories ralph expects
RUN mkdir -p /workspace/tasks /workspace/archive

# Config directory for agy settings (mounted from host)
RUN mkdir -p /root/.config/agy

# Entrypoint: keep container alive so you can exec into it
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
