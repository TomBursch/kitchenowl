#
# swoop_docker
#
FROM python:3.12-slim
RUN apt-get update -y
RUN apt-get upgrade -y

RUN apt-get install -y --no-install-recommends \
    apt-utils \
    curl \
    git \
    wget \
    python3 \
    python3-pip \
    python3-venv

RUN apt-get autoremove -y
WORKDIR /usr/src/app
COPY  swoop_data /usr/src/app/swoop
RUN chmod +x /usr/src/app/swoop/scraper.py

RUN adduser --system --no-create-home --shell /bin/bash swoop

RUN chown -Rh swoop:root /usr/src/app
RUN python3 -m venv /usr/src/app/venv 
RUN /usr/src/app/venv/bin/pip3 install --no-cache-dir pip setuptools wheel
RUN /usr/src/app/venv/bin/pip3 install --no-cache-dir -r /usr/src/app/swoop/requirements.txt

USER swoop
WORKDIR /usr/src/app
ENV PATH="/usr/src/app/venv/bin:$PATH"

ENTRYPOINT [ "/bin/bash", "-c", "exec bash && source /usr/src/app/venv/bin/activate" ]



