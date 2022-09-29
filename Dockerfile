FROM debian:11-slim

# Set version label
LABEL maintainer="Benjamin Jonard <jonard.benjamin@gmail.com>"

ARG GITHUB_RELEASE

# Environment variables
ENV PUID='1000'
ENV PGID='1000'
ENV USER='mendako'
ENV PHP_TZ=Europe/Paris
ENV APP_ENV=prod
ENV APP_DEBUG=0
ENV HTTPS_ENABLED=$HTTPS_ENABLED

ENV BUILD_DEPS=""

COPY entrypoint.sh inject.sh /

RUN \
# Add User and Group
    addgroup --gid "$PGID" "$USER" && \
    adduser --gecos '' --no-create-home --disabled-password --uid "$PUID" --gid "$PGID" "$USER" && \
# Install dependencies
    apt-get update && \
    apt-get install -y $BUILD_DEPS curl wget lsb-release  && \
# PHP
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list && \
# Nodejs
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
# Yarn
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y \
    ca-certificates \
    apt-transport-https \
    gnupg2 \
    git \
    unzip \
    nginx-light \
    openssl \
    ffmpeg \
    php8.1 \
    php8.1-pgsql \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-gd \
    php8.1-xml \
    php8.1-zip \
    php8.1-fpm \
    php8.1-intl \
    php8.1-apcu \
    nodejs \
    yarn && \
# Composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
# Clone the repo
    mkdir -p /var/www/mendako && \
    curl -o /tmp/mendako.tar.gz -L "https://github.com/benjaminjonard/mendako/archive/main.tar.gz" && \
    tar xf /tmp/mendako.tar.gz -C /var/www/mendako --strip-components=1 && \
    rm -rf /tmp/* && \
    cd /var/www/mendako && \
    composer install --no-dev --classmap-authoritative && \
    composer clearcache && \
# Build assets \
    cd ./assets && \
    yarn --version && \
    yarn install && \
    yarn build && \
    cd /var/www/mendako && \
# Clean up \
    yarn cache clean && \
    rm -rf ./assets/node_modules && \
    apt-get purge -y wget lsb-release git nodejs yarn apt-transport-https ca-certificates gnupg2 unzip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/local/bin/composer && \
# Set permisions \
    chown -R "$USER":"$USER" /var/www/mendako && \
    chmod +x /entrypoint.sh && \
    chmod +x /inject.sh && \
    mkdir /run/php

# Add custom site to apache
COPY default.conf /etc/nginx/nginx.conf
COPY php.ini /etc/php/8.1/fpm/conf.d/php.ini

EXPOSE 80

VOLUME /conf /uploads

WORKDIR /var/www/mendako

HEALTHCHECK CMD curl --fail http://localhost:80/ || exit 1

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "nginx" ]
