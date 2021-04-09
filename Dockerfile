FROM alpine:3.12 as main

LABEL maintainer="hooklife <hooklife@qq.com>" version="1.0" license="MIT"


# trust this project public key to trust the packages.
ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

ARG SW_VERSION
ARG ALPINE_VERSION=3.12

ENV SW_VERSION=${SW_VERSION:-"v4.6.4"} \
    PHP_VERSION=${PHP_VERSION:-8.0} \
    TIME_ZONE=Asia/Shanghai \
    #  install and remove building packages
    PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make php8-dev pkgconf re2c pcre-dev pcre2-dev zlib-dev libtool automake"

##
# ---------- building ----------
##
RUN set -ex; \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    # change apk source repo
    && apk --update add ca-certificates \
    && echo "https://dl.bintray.com/php-alpine/v$ALPINE_VERSION/php-$PHP_VERSION" >> /etc/apk/repositories\
    && apk update \
    && apk add --no-cache \
    # Install base packages ('ca-certificates' will install 'nghttp2-libs')
    libstdc++ \
    openssl \
    tini \
    tzdata \
    php8 \
    php8-bcmath \
    php8-curl \
    php8-ctype \
    php8-dom \
    php8-gd \
    php8-iconv \
    php8-mbstring \
    php8-mysqlnd \
    php8-openssl \
    php8-pdo \
    php8-pdo_mysql \
    php8-pdo_sqlite \
    php8-phar \
    php8-posix \
    php8-redis \
    php8-sockets \
    php8-sodium \
    php8-sysvshm \
    php8-sysvmsg \
    php8-sysvsem \
    php8-zip \
    php8-zlib \
    php8-xml \
    php8-xmlreader \
    php8-pcntl \
    php8-session \
    php8-opcache \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS curl tar libaio-dev openssl-dev curl-dev \
    && cd /tmp \
    && curl -SL "https://github.com/swoole/swoole-src/archive/${SW_VERSION}.tar.gz" -o swoole.tar.gz \
    && cd /tmp \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && ln -s /usr/bin/phpize8 /usr/local/bin/phpize \
    && ln -s /usr/bin/php-config8 /usr/local/bin/php-config \
    && ( \
    cd swoole \
    && phpize \
    && ./configure --enable-openssl --enable-http2 --enable-swoole-curl --enable-swoole-json \
    && make -s -j$(nproc) && make install \
    ) \
    # install composer
    && ln -sf /usr/bin/php8 /usr/bin/php \
    # timezone
    && ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime \
    && echo "${TIME_ZONE}" > /etc/timezone \
    # delete apk
    && apk del .build-deps\
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/local/bin/php* \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"

COPY rootfs /

EXPOSE 80
WORKDIR /app
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["php","artisan","octane:start","--host=0.0.0.0","--port=80"]


FROM main as dev
RUN apk add -U --no-cache \
    git \
    curl \
    wget \
    make \
    zip \
    iputils \
    nodejs \
    npm \
    && rm -rf /var/cache/apk/* \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer --version
CMD ["php","/app/artisan","octane:start","--host=0.0.0.0","--port=80","--watch" ]