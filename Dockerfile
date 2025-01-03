ARG ALPINE_VERSION=latest
ARG LIBSIG_VERSION=3.6.0
ARG CARES_VERSION=1.34.4
ARG CURL_VERSION=8.11.1
ARG GEOIP2_PHPEXT_VERSION=1.3.1
ARG XMLRPC_VERSION=1.64.00
ARG LIBTORRENT_VERSION=0.14.0
ARG RTORRENT_VERSION=0.10.0
ARG MM_COMMON_VERSION=1.0.6
ARG RUTORRENT_REVISION=25679a45a1e2ca9f7a9e01cab5cc554b8eaa7230

FROM alpine:${ALPINE_VERSION} AS compile

ENV DIST_PATH="/dist"

RUN apk --update --no-cache add \
    autoconf \
    autoconf-archive \
    automake \
    binutils \
    brotli-dev \
    build-base \
    curl \
    cppunit-dev \
    fftw-dev \
    gd-dev \
    geoip-dev \
    git \
    libnl3 \
    libnl3-dev \
    libtool \
    libpsl-dev \
    libxslt-dev \
    linux-headers \
    ncurses-dev \
    nghttp2-dev \
    openssl-dev \
    pcre-dev \
    php83-dev \
    php83-pear \
    subversion \
    tar \
    tree \
    xz \
    zlib-dev

ARG MM_COMMON_VERSION
WORKDIR /tmp/common
RUN curl -sSL "http://ftp.gnome.org/pub/GNOME/sources/mm-common/1.0/mm-common-${MM_COMMON_VERSION}.tar.xz" | tar -xJ --strip 1
RUN ./autogen.sh --prefix=/usr/local 
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)
RUN cp -r /usr/local/share/aclocal/* /usr/share/aclocal/

ARG LIBSIG_VERSION
WORKDIR /tmp/libsig
RUN curl -sSL "http://ftp.gnome.org/pub/GNOME/sources/libsigc++/3.6/libsigc++-${LIBSIG_VERSION}.tar.xz" | tar -xJ --strip 1
RUN ./autogen.sh --prefix=/usr/local
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG CARES_VERSION
WORKDIR /tmp/cares
RUN curl -sSL "https://github.com/c-ares/c-ares/releases/download/v${CARES_VERSION}/c-ares-${CARES_VERSION}.tar.gz" | tar -xz --strip 1
RUN ./configure
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG CURL_VERSION
WORKDIR /tmp/curl
RUN curl -sSL "https://curl.se/download/curl-${CURL_VERSION}.tar.gz" | tar -xz --strip 1
RUN ./configure \
  --enable-ares \
  --enable-tls-srp \
  --enable-gnu-tls \
  --with-brotli \
  --with-ssl \
  --with-zlib
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG GEOIP2_PHPEXT_VERSION
WORKDIR /tmp/geoip2-phpext
RUN git clone -q "https://github.com/rlerdorf/geoip" . && git reset --hard ${GEOIP2_PHPEXT_VERSION} && rm -rf .git
RUN set -e
RUN phpize83
RUN ./configure --with-php-config=/usr/bin/php-config83
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG XMLRPC_VERSION
WORKDIR /tmp/xmlrpc-c
RUN svn checkout -q "http://svn.code.sf.net/p/xmlrpc-c/code/release_number/${XMLRPC_VERSION}/" . && rm -rf .svn
RUN ./configure \
   --disable-wininet-client \
   --disable-libwww-client \
   --disable-abyss-server \
   --disable-cgi-server
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)
RUN mkdir -p ${DIST_PATH}/usr/lib/php83/modules
RUN cp -f /usr/lib/php83/modules/geoip.so ${DIST_PATH}/usr/lib/php83/modules/

ARG LIBTORRENT_VERSION
WORKDIR /tmp/libtorrent
RUN git clone -q "https://github.com/rakshasa/libtorrent" . && git reset --hard v${LIBTORRENT_VERSION} && rm -rf .git
RUN libtoolize --force && aclocal && autoheader && automake --add-missing && autoconf
RUN ./configure \
  --with-posix-fallocate \
  --enable-aligned \
  --disable-instrumentation \
  --enable-udns
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG RTORRENT_VERSION
WORKDIR /tmp/rtorrent
RUN git clone -q "https://github.com/rakshasa/rtorrent" . && git reset --hard v${RTORRENT_VERSION} && rm -rf .git
RUN libtoolize --force && aclocal && autoheader && automake --add-missing && autoconf
RUN ./configure \
  --with-xmlrpc-c \
  --with-ncurses
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS download

RUN apk --update --no-cache add curl git tar xz

ARG RUTORRENT_REVISION
WORKDIR /dist/rutorrent
RUN git clone -q "https://github.com/Novik/ruTorrent" . && git reset --hard ${RUTORRENT_REVISION} && rm -rf .git
RUN rm -rf conf/users plugins/dump plugins/geoip plugins/_cloudflare share

WORKDIR /dist/rutorrent-geoip2
RUN git clone -q "https://github.com/Micdu70/geoip2-rutorrent" . && rm -rf .git

WORKDIR /dist/rutorrent-filemanager
RUN git clone -q "https://github.com/nelu/rutorrent-filemanager" . 

WORKDIR /dist/rutorrent-ratio
RUN git clone -q "https://github.com/Gyran/rutorrent-ratiocolor" . && rm -rf .git

WORKDIR /dist/rutorrent-theme-quick
RUN git clone -q "https://github.com/QuickBox/club-QuickBox" . && rm -rf .git

FROM golang:alpine AS geoip2

ARG MM_ACCOUNT
ARG MM_LICENSE
WORKDIR /dist/mmdb
RUN apk --update --no-cache add git
ENV GOPATH=/opt/geoipupdate GOMAXPROCS=1
RUN VERSION=$(git ls-remote --tags "https://github.com/maxmind/geoipupdate"| \
    awk '{print $2}' | sed 's/refs\/tags\///;s/\..*$//' | sort -uV | tail -1) \
    && go install github.com/maxmind/geoipupdate/$VERSION/cmd/geoipupdate@latest
RUN cat > /etc/geoip2.conf <<EOL
AccountID ${MM_ACCOUNT}
LicenseKey ${MM_LICENSE}
EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country
EOL
RUN /opt/geoipupdate/bin/geoipupdate -v -f /etc/geoip2.conf -d ./

ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS builder

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

RUN apk --update --no-cache add unrar --repository=http://dl-cdn.alpinelinux.org/alpine/v3.14/main
RUN apk --update --no-cache add \
    apache2-utils \
    bash \
    bind-tools \
    binutils \
    brotli \
    ca-certificates \
    coreutils \
    cppunit-dev \
    ffmpeg \
    findutils \
    geoip \
    grep \
    gzip \
    htop \
    libstdc++ \
    mediainfo \
    nano \
    ncurses \
    nginx \
    nginx-mod-http-brotli \
    nginx-mod-http-headers-more \
    nginx-mod-http-dav-ext \
    nginx-mod-http-geoip2 \
    mktorrent \
    openssl \
    pcre \
    php83 \
    php83-bcmath \
    php83-cli \
    php83-ctype \
    php83-curl \
    php83-dom \
    php83-fpm \
    php83-json \
    php83-mbstring \
    php83-openssl \
    php83-opcache \
    php83-pecl-apcu \
    php83-pear \
    php83-phar \
    php83-posix \
    php83-session \
    php83-sockets \
    php83-xml \
    php83-zip \
    php83-zlib \
    python3 \
    py3-pip \
    py3-virtualenv \
    p7zip \
    s6-overlay \
    shadow \
    sox \
    tar \
    tzdata \
    unzip \
    util-linux \
    zip \
    zlib \
  && python3 -m venv /opt/venv \
  && . /opt/venv/bin/activate \
  && pip install --upgrade pip \
  && deactivate \
  && addgroup -g ${PGID} rtorrent \
  && adduser -D -H -u ${PUID} -G rtorrent -s /bin/sh rtorrent \
  && rm -rf /tmp/* /var/cache/apk/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/php83/access.log && \
    ln -sf /dev/stderr /var/log/php83/error.log

COPY rootfs /
COPY --from=compile /dist /
COPY --from=geoip2 /dist/mmdb /var/mmdb
COPY --from=geoip2 /opt/geoipupdate/bin/geoipupdate /usr/local/bin/
COPY --from=download --chown=nobody:nogroup /dist/rutorrent /var/www/rutorrent
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-geoip2 /var/www/rutorrent/plugins/geoip2
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-filemanager /var/www/rutorrent/plugins/filemanager
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-ratio /var/www/rutorrent/plugins/ratiocolor
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-quick /var/www/rutorrent/plugins/theme/themes/QuickBox

VOLUME [ "/config", "/data", "/passwd" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD /usr/local/bin/healthcheck
