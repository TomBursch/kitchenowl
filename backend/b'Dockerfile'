# ------------
# BUILDER
# ------------
FROM python:3.10-slim as builder

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        gcc g++ libffi-dev libpcre3-dev build-essential cargo

# Create virtual enviroment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install wheel && pip install -r requirements.txt

# ------------
# RUNNER
# ------------
FROM python:3.10-slim as runner

# Use virtual enviroment
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Setup KitchenOwl
COPY wsgi.ini wsgi.py entrypoint.sh /usr/src/kitchenowl/
COPY app /usr/src/kitchenowl/app
COPY templates /usr/src/kitchenowl/templates
COPY migrations /usr/src/kitchenowl/migrations
WORKDIR /usr/src/kitchenowl
VOLUME ["/data"]

ENV STORAGE_PATH='/data'
ENV JWT_SECRET_KEY='PLEASE_CHANGE_ME'
ENV DEBUG='False'
ENV HTTP_PORT=80

RUN chmod u+x ./entrypoint.sh

CMD ["wsgi.ini"]
ENTRYPOINT ["./entrypoint.sh"]
