# ------------
# BUILDER
# ------------
FROM --platform=$BUILDPLATFORM debian:latest AS builder

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
COPY .metadata l10n.yaml pubspec.yaml pubspec.lock /usr/local/src/app/
COPY lib /usr/local/src/app/lib
COPY web /usr/local/src/app/web
COPY assets /usr/local/src/app/assets
COPY fonts /usr/local/src/app/fonts

# Set the working directory to the app files within the container
WORKDIR /usr/local/src/app

# Get App Dependencies
RUN flutter packages get

# Build the app for the web
RUN flutter build web --release --no-web-resources-cdn

# ------------
# RUNNER
# ------------
FROM nginx:stable-alpine

RUN apk add --no-cache bash
RUN mkdir -p /var/www/web/kitchenowl
COPY --from=builder /usr/local/src/app/build/web /var/www/web/kitchenowl
COPY docker-entrypoint-custom.sh /docker-entrypoint.d/01-kitchenowl-customization.sh
COPY default.conf.template /etc/nginx/templates/

HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/ || exit 1

# Set ENV
ENV BACK_URL='back:5000'

# Expose the web server
EXPOSE 80