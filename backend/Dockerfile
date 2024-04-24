# ------------
# BUILDER
# ------------
FROM python:3.12-slim as builder

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        gcc g++ libffi-dev libpcre3-dev build-essential cargo \
        libxml2-dev libxslt-dev cmake gfortran libopenblas-dev liblapack-dev pkg-config ninja-build \
         autoconf automake zlib1g-dev libjpeg62-turbo-dev libssl-dev libsqlite3-dev

# Create virtual enviroment
RUN python -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir -U pip setuptools wheel
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt && find /opt/venv \( -type d -a -name test -o -name tests \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \+

RUN python -c "import nltk; nltk.download('averaged_perceptron_tagger', download_dir='/opt/venv/nltk_data')"

# ------------
# RUNNER
# ------------
FROM python:3.12-slim as runner

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        libxml2 libpcre3 curl \
    && rm -rf /var/lib/apt/lists/*

# Use virtual enviroment
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Setup KitchenOwl
COPY wsgi.ini wsgi.py entrypoint.sh manage.py manage_default_items.py upgrade_default_items.py /usr/src/kitchenowl/
COPY app /usr/src/kitchenowl/app
COPY templates /usr/src/kitchenowl/templates
COPY migrations /usr/src/kitchenowl/migrations
WORKDIR /usr/src/kitchenowl
VOLUME ["/data"]

HEALTHCHECK --interval=60s --timeout=3s CMD uwsgi_curl localhost:5000 /api/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V || exit 1

ENV STORAGE_PATH='/data'
ENV JWT_SECRET_KEY='PLEASE_CHANGE_ME'
ENV DEBUG='False'

RUN chmod u+x ./entrypoint.sh

CMD ["wsgi.ini", "--gevent", "200"]
ENTRYPOINT ["./entrypoint.sh"]
