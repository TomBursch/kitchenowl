FROM python:3.8

## Setup Shoppy
COPY . /usr/src/kitchenowl/
WORKDIR /usr/src/kitchenowl
VOLUME ["/data"]
ENV STORAGE_PATH='/data'
ENV JWT_SECRET_KEY='PLEASE_CHANGE_ME'
ENV DEBUG='False'
RUN pip3 install -r requirements.txt && rm requirements.txt
RUN flask db upgrade
RUN chmod u+x ./entrypoint.sh

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost:5000/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V || exit 1

EXPOSE 5000
ENTRYPOINT ["./entrypoint.sh"]
