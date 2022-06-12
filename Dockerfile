# ------------
# BUILDER
# ------------
FROM debian:latest AS builder

# Install dependencies
RUN apt-get update -y
RUN apt-get upgrade -y
# Install basics
RUN apt-get install -y --no-install-recommends \
  git \
  wget \
  curl \
  zip \
  unzip \
  apt-transport-https \
  ca-certificates \
  gnupg \
  python3 \
  libstdc++6 \
  libglu1-mesa
RUN apt-get clean

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/src/flutter

# Set flutter path
ENV PATH="${PATH}:/usr/local/src/flutter/bin"

# Enable flutter web
RUN flutter config --enable-web
RUN flutter config --no-analytics
RUN flutter upgrade

# Run flutter doctor
RUN flutter doctor -v

# Copy the app files to the container
COPY .metadata l10n.yaml pubspec.yaml .env* entrypoint.sh /usr/local/src/app/
COPY lib /usr/local/src/app/lib
COPY web /usr/local/src/app/web
COPY scripts /usr/local/src/app/scripts
COPY assets /usr/local/src/app/assets
RUN touch /usr/local/src/app/.env

# Set the working directory to the app files within the container
WORKDIR /usr/local/src/app

# Get App Dependencies
RUN flutter packages get

# Build the app for the web
RUN flutter build web

# ------------
# RUNNER
# ------------
FROM nginx:stable-alpine

RUN mkdir -p /var/www/web/kitchenowl
COPY --from=builder /usr/local/src/app/build/web /var/www/web/kitchenowl
COPY entrypoint.sh /docker-entrypoint.d/
COPY default.conf.template /etc/nginx/templates/

# Set the server startup script as executable
RUN chmod u+x /docker-entrypoint.d/entrypoint.sh

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost/api/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V || exit 1

# Set ENV
ENV BACK_URL='back:5000'
ENV FRONT_URL='http://localhost'

# Expose the web server
EXPOSE 80