FROM ghcr.io/lmangueira/claude-containers/claude-base:latest

RUN apt-get update && apt-get install -y \
    tmux vim ripgrep fd-find jq tree \
    less man-db \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY tmux.conf /home/claude/.tmux.conf
RUN chown claude:claude /home/claude/.tmux.conf

COPY bashrc_extra /tmp/bashrc_extra
RUN cat /tmp/bashrc_extra >> /home/claude/.bashrc && rm /tmp/bashrc_extra
