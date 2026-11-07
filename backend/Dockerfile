# ------------
# BUILDER
# ------------
FROM python:3.14-slim AS builder

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        gcc g++ libffi-dev libpcre2-dev libre2-dev build-essential cargo \
        libxml2-dev libxslt-dev cmake gfortran libopenblas-dev liblapack-dev pkg-config ninja-build \
        autoconf automake zlib1g-dev libjpeg62-turbo-dev libssl-dev libsqlite3-dev libexpat1-dev \
        libicu-dev

# Create virtual enviroment
RUN pip install uv
ENV UV_PROJECT_ENVIRONMENT="/opt/venv"
ENV PATH="/opt/venv/bin:$PATH"

COPY pyproject.toml uv.lock ./
RUN uv python list --no-managed-python && uv sync --no-dev && find /opt/venv \( -type d -a -name test -o -name tests \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \+

RUN python -c "import nltk; nltk.download('averaged_perceptron_tagger_eng', download_dir='/opt/venv/nltk_data')"

# ------------
# RUNNER
# ------------
FROM python:3.14-slim AS runner

LABEL org.opencontainers.image.source="https://github.com/TomBursch/kitchenowl"

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        libxml2 libpcre2-dev libre2-dev libexpat1 curl \
        media-types libicu-dev gosu \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 kitchenowl \
    && useradd -u 1000 -g kitchenowl -d /usr/src/kitchenowl -s /sbin/nologin kitchenowl

# Use virtual enviroment
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Setup KitchenOwl
RUN mkdir -p /usr/src/kitchenowl /data && chown kitchenowl:kitchenowl /usr/src/kitchenowl /data
COPY --chown=kitchenowl:kitchenowl wsgi.ini wsgi.py entrypoint.sh manage.py manage_default_items.py upgrade_default_items.py /usr/src/kitchenowl/
COPY --chown=kitchenowl:kitchenowl app /usr/src/kitchenowl/app
COPY --chown=kitchenowl:kitchenowl templates /usr/src/kitchenowl/templates
COPY --chown=kitchenowl:kitchenowl migrations /usr/src/kitchenowl/migrations
WORKDIR /usr/src/kitchenowl
VOLUME ["/data"]

HEALTHCHECK --interval=60s --timeout=3s CMD uwsgi_curl localhost:5000 /api/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V || exit 1

ENV STORAGE_PATH='/data'
ENV JWT_SECRET_KEY='PLEASE_CHANGE_ME'
ENV DEBUG='False'

RUN chmod u+x ./entrypoint.sh

CMD ["wsgi.ini", "--gevent", "200", "--max-fd", "1048576"]
ENTRYPOINT ["./entrypoint.sh"]
