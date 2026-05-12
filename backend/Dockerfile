FROM python:3.7.11-bullseye

LABEL org.opencontainers.image.title="Pneumatic API" \
      org.opencontainers.image.source="https://github.com/pneumaticapp/pneumaticworkflow/backend" \
      org.opencontainers.image.url="https://www.pneumatic.app" \
      org.opencontainers.image.authors="support@pneumatic.app" \
      org.opencontainers.image.vendor="Pneumatic Software Inc." \
      org.opencontainers.image.documentation="https://github.com/pneumaticapp/pneumaticworkflow/wiki" \
      org.opencontainers.image.licenses="Apache-2.0"

# Install Internationalization requirements
RUN apt-get update && \
    apt-get -y install gettext postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# The enviroment variable ensures that the python output is set straight
# to the terminal with out buffering it first

# Use pip with exported requirements.txt for faster install (vs poetry)
COPY ./requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

WORKDIR /pneumatic_backend
COPY . .
