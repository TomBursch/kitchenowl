# Install dependencies
FROM debian:latest

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
  lib32stdc++6 \
  libstdc++6 \
  libglu1-mesa
RUN apt-get clean

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/src/flutter

# Set flutter path
ENV PATH="${PATH}:/usr/local/src/flutter/bin"

# Enable flutter web
RUN flutter config --enable-web
RUN flutter upgrade

# Run flutter doctor
RUN flutter doctor -v

# Copy the app files to the container
COPY .metadata l10n.yaml pubspec.yaml .env* entrypoint.sh /usr/local/src/app/
COPY lib /usr/local/src/app/lib
COPY web /usr/local/src/app/web
COPY scripts /usr/local/src/app/scripts
COPY assets /usr/local/src/app/assets
RUN touch /usr/local/src/app/.env

# Set the working directory to the app files within the container
WORKDIR /usr/local/src/app

# Get App Dependencies
RUN flutter packages get

# Build the app for the web
RUN flutter build web

RUN mkdir /usr/local/web/
RUN ls
RUN cp -r ./build/web/* ./entrypoint.sh /usr/local/web/
WORKDIR /usr/local/web

# Clean up files
RUN rm -r /usr/local/src/app
RUN rm -r /usr/local/src/flutter

# Set the server startup script as executable
RUN chmod u+x ./entrypoint.sh

# Set ENV
ENV BACK_URL='http://localhost:5000'

# Start the web server
EXPOSE 80
ENTRYPOINT [ "./entrypoint.sh" ]