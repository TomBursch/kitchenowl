# ------------
# WEB BUILDER
# ------------
FROM --platform=$BUILDPLATFORM debian:latest AS app_builder

# Install dependencies
RUN apt update -y && apt upgrade -y && apt install -y --no-install-recommends \
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
  libglu1-mesa \
  libglu1-mesa && apt clean
# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/src/flutter



# Set flutter path
ENV PATH="${PATH}:/usr/local/src/flutter/bin"

# Enable flutter web
RUN flutter config --enable-web
RUN flutter config --no-analytics
RUN flutter upgrade

# Create a new user and group
RUN useradd -ms /bin/bash flutteruser

# Set ownership of the flutter directory to this new user
RUN mkdir -p /usr/local/src/app && chown -R flutteruser:flutteruser /usr/local/src/app /usr/local/src/flutter
# Switch to that user
USER flutteruser
ENV PATH="${PATH}:/usr/local/src/flutter/bin"



RUN flutter doctor -v
# Set the working directory to the app files within the container
WORKDIR /usr/local/src/app

RUN flutter packages get

# Build the app for the web
RUN flutter build web --release --no-web-resources-cdn


# Copy the app files to the container
COPY kitchenowl/.metadata kitchenowl/l10n.yaml kitchenowl/pubspec.yaml kitchenowl/pubspec.lock /usr/local/src/app/
COPY kitchenowl/web /usr/local/src/app/web
COPY kitchenowl/assets /usr/local/src/app/assets
COPY kitchenowl/fonts /usr/local/src/app/fonts


RUN flutter test

RUN flutter clean

# ------------
# BACKEND BUILDER
# ------------
FROM --platform=$BUILDPLATFORM python:3.12-slim AS backend_builder

RUN apt update && apt install --yes --no-install-recommends \
        gcc g++ libffi-dev libpcre3-dev build-essential cargo \
        libxml2-dev libxslt-dev cmake gfortran libopenblas-dev liblapack-dev pkg-config ninja-build \
        autoconf automake zlib1g-dev libjpeg62-turbo-dev libssl-dev libsqlite3-dev && rm -rf /var/lib/apt/lists/*

# Create virtual enviroment
RUN python -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir -U pip setuptools wheel
ENV PATH="/opt/venv/bin:$PATH"

COPY backend/requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt && find /opt/venv \( -type d -a -name test -o -name tests \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \+
RUN pip3 install --no-cache-dir -r requirements.txt \
    && find /opt/venv \( -type d -a -name test -o -name tests \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \+
RUN python -c "import nltk; nltk.download('averaged_perceptron_tagger_eng', download_dir='/opt/venv/nltk_data')"

# ------------
# RUNNER
# ------------
FROM --platform=$BUILDPLATFORM python:3.12-slim AS runner
RUN apt update && apt install --yes --no-install-recommends \
        libxml2 libpcre3 curl media-types && rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/lib/apt/lists/*

# Use virtual enviroment
COPY --from=backend_builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Setup Frontend
RUN mkdir -p /var/www/web/kitchenowl
COPY --from=app_builder /usr/local/src/app/build/web /var/www/web/kitchenowl

# Setup KitchenOwl Backend
COPY backend/wsgi.ini backend/wsgi.py backend/entrypoint.sh backend/manage.py backend/manage_default_items.py backend/upgrade_default_items.py /usr/src/kitchenowl/
COPY backend/app /usr/src/kitchenowl/app
COPY backend/templates /usr/src/kitchenowl/templates
COPY backend/migrations /usr/src/kitchenowl/migrations
WORKDIR /usr/src/kitchenowl
VOLUME ["/data"]

# HEALTHCHECK --interval=60s --timeout=3s CMD curl --fail http://localhost:5000/api/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V || exit 1

ENV STORAGE_PATH='/data'
ENV JWT_SECRET_KEY='PLEASE_CHANGE_ME'
ENV DEBUG=False

HEALTHCHECK --interval=60s --timeout=3s CMD curl --fail http://localhost:5000/api/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V || exit 1
ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 8080
