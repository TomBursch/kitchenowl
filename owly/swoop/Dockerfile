#
# swoop_docker
#
FROM --platform=$BUILDPLATFORM python:3.12-slim-bookworm  AS swoop_builder
RUN apt-get update -y
RUN apt-get upgrade -y

RUN apt-get install -y \
    curl \
    git \
    wget \
    python3 \
    python3-pip \
    python3-venv


RUN apt-get autoremove -y



WORKDIR /usr/src/app

COPY requirements.txt ./




RUN python3 -m venv /usr/src/app/venv

RUN adduser --system --group --no-create-home swoop 
RUN chown -Rh swoop:swoop /usr/src/app/

USER swoop
RUN . /usr/src/app/venv/bin/activate
RUN /usr/src/app/venv/bin/python -m pip install --upgrade pip && \
    /usr/src/app/venv/bin/pip install -r requirements.txt



