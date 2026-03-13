FROM ghcr.io/lmangueira/claude-containers/claude-base:latest

RUN apt-get update && apt-get install -y \
    wget tar xz-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
