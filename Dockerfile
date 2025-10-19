# Käytetään virallista devcontainers-pohjaa (Python 3.11)
FROM mcr.microsoft.com/devcontainers/python:3.11

# Päivitetään ja asennetaan perusriippuvuudet
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git curl jq ca-certificates apt-transport-https lsb-release gnupg build-essential && \
    rm -rf /var/lib/apt/lists/*

# Asennetaan Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Asennetaan Python-työkalut konttiin (vain tänne, ei hostille)
RUN pip install --no-cache-dir \
    dbt-snowflake \
    snowflake-cli-labs \
    streamlit \
    pandas \
    jinja2

# Asetetaan oletustyökansio
WORKDIR /workspace

# Käyttäjä ja ympäristö
USER vscode
ENV PYTHONUNBUFFERED=1
