# This is a locally modified version of the upstream CKAN Dockerfile

# See CKAN docs on installation from Docker Compose on usage
FROM ubuntu:jammy
LABEL org.opencontainers.image.authors="Yoda team"

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setting the locale
ENV LC_ALL=en_US.UTF-8
RUN adduser ckan
RUN apt-get update
RUN apt-get install --no-install-recommends -y locales
RUN sed -i "/$LC_ALL/s/^# //g" /etc/locale.gen
RUN dpkg-reconfigure --frontend=noninteractive locales
RUN update-locale LANG=${LC_ALL}

# Install required system packages
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
        python3.10 \
        python3-dev \
        python3-pip \
        python3-venv \
        python3-wheel \
        libpq-dev \
        python3-pastescript \
        python3-virtualenv \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        libmagic1 \
        libmagic-dev \
        postgresql-client \
        build-essential \
        git-core \
        vim \
        wget \
        curl \
        nmap \
        sqlite3 \
        pwgen \
        uuid-runtime \
        sudo \
        vim  \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/default
ENV CKAN_CONFIG /etc/ckan
ENV CKAN_STORAGE_PATH=/ckanstorage
ENV CKAN_VERSION=2.11.0

# Create storage path
RUN mkdir -p $CKAN_STORAGE_PATH/webassets $CKAN_STORAGE_PATH/storage && \
    chown -R www-data:www-data $CKAN_STORAGE_PATH

# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG/default && \
    python3 -m venv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip3 /usr/local/bin/ckan-pip3 &&\
    ln -s $CKAN_VENV/bin/ckan /usr/local/bin/ckan
ADD ckan.ini /etc/ckan/default/ckan.ini
ADD who.ini /etc/ckan/default/who.ini
ADD wsgi.py /etc/ckan/default/wsgi.py
ADD ckan-uwsgi.ini /etc/ckan/default/ckan-uwsgi.ini

# Virtual environment binaries/scripts to be used first
ENV PATH=${CKAN_VENV}/bin:${PATH}
ENV LEXCES_CATALOG_HOST=${LEXCES_CATALOG_HOST}
ENV CKAN_ADMIN_PASSWORD=${CKAN_ADMIN_PASSWORD}

# Install CKAN and plugins
# Newer versions of setuptools-scm don't work with current version of CKAN because of setuptools version dependency
RUN ckan-pip3 install -U pip && \
    ckan-pip3 install --upgrade pip && \
    ckan-pip3 install setuptools-scm==7.1.0 && \
    ckan-pip3 install wheel && \
    ckan-pip3 install -e "git+https://github.com/ckan/ckan@ckan-${CKAN_VERSION}#egg=ckan[requirements]" && \
    ckan-pip3 install uwsgi && \
    ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini && \
    chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH

ADD ./ckan-entrypoint.sh /ckan-entrypoint.sh
ENTRYPOINT ["/ckan-entrypoint.sh"]
RUN chmod +x /ckan-entrypoint.sh

USER root
EXPOSE 8080

CMD ["/ckan-entrypoint.sh"]
