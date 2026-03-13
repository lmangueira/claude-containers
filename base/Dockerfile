FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    curl ca-certificates gnupg \
    openssh-server \
    iproute2 iptables \
    git python3 build-essential procps libatomic1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g --prefix /opt/claude-code @anthropic-ai/claude-code
ENV PATH="/opt/claude-code/bin:$PATH"
RUN echo 'export PATH="/opt/claude-code/bin:$PATH"' > /etc/profile.d/claude-code.sh

RUN curl -fsSL https://tailscale.com/install.sh | sh

RUN mkdir /var/run/sshd && \
    sed -i \
        -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' \
        -e 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
    /etc/ssh/sshd_config

RUN useradd -m -s /bin/bash claude && \
    mkdir -p /home/claude/.ssh && \
    chmod 700 /home/claude/.ssh

RUN mkdir -p /workspace && chown claude:claude /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /usr/share/terminfo/x
COPY xterm-ghostty /usr/share/terminfo/x/xterm-ghostty

VOLUME ["/home/claude", "/workspace"]

ENTRYPOINT ["/entrypoint.sh"]
