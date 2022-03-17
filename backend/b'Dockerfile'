FROM python:3.10-slim

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        gcc g++ libffi-dev

## Setup KitchenOwl
COPY requirements.txt wsgi.ini wsgi.py entrypoint.sh /usr/src/kitchenowl/
COPY app /usr/src/kitchenowl/app
COPY templates /usr/src/kitchenowl/templates
COPY migrations /usr/src/kitchenowl/migrations
WORKDIR /usr/src/kitchenowl
VOLUME ["/data"]

ENV STORAGE_PATH='/data'
ENV JWT_SECRET_KEY='PLEASE_CHANGE_ME'
ENV DEBUG='False'

RUN pip3 install -r requirements.txt && rm requirements.txt
RUN chmod u+x ./entrypoint.sh

# Cleanup
RUN apt-get autoremove --yes gcc g++ libffi-dev \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80

USER 1000
CMD ["wsgi.ini"]
ENTRYPOINT ["./entrypoint.sh"]
