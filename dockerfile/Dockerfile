FROM debian:bullseye-slim

RUN set -ex \
    && apt update \
    && apt install -yq --no-install-recommends \
#        gettext-base \
        gosu \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -ex \
   && groupadd -g 1000 user \
   && useradd -u 1000 -g user -s /bin/bash -m user

COPY . /usr/bin

RUN set -ex && chmod +x /usr/bin/*.sh
