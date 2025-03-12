#
# swoop_docker
#
FROM debian:stable-slim
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

COPY  pyfiles /usr/src/app/pyfiles


RUN python3 -m venv /usr/src/app/venv
ENV PATH="${PATH}:/usr/src/app/venv/bin"

RUN adduser --system --home /home/swoop --shell /bin/bash swoop
RUN chmod +x /usr/src/app/pyfiles/scraper.py
RUN chmod +x /usr/src/app/venv/bin/activate

RUN chown -R  swoop:root /usr/src/app/
USER swoop
ENV PATH="${PATH}:/usr/src/app/venv/bin"

RUN source /usr/src/app/venv/bin/activate
RUN pip install --upgrade pip
RUN pip install -r /usr/src/app/pyfiles/requirements.txt
