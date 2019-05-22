FROM rust:1.34-slim

RUN rustup target add x86_64-unknown-linux-musl && \
  echo "[build]\ntarget = \"x86_64-unknown-linux-musl\"" > $CARGO_HOME/config

RUN apt-get update && apt-get install -y \
  musl-dev \
  musl-tools \
  git \
  make \
  g++ \
  curl \
  pkgconf \
  ca-certificates \
  xutils-dev \
  libssl-dev \
  libpq-dev \
  automake \
  autoconf \
  libtool \
  --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

ENV SSL_VER="1.0.2r" \
  CURL_VER="7.64.1" \
  ZLIB_VER="1.2.11" \
  CC=musl-gcc \
  PREFIX=/musl \
  PATH=/usr/local/bin:$CARGO_HOME/bin:$PATH \
  PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
  LD_LIBRARY_PATH=$PREFIX

# Set up a prefix for musl build libraries, make the linker's job of finding them easier
# Primarily for the benefit of postgres.
# Lastly, link some linux-headers for openssl 1.1 (not used herein)
RUN mkdir $PREFIX && \
  echo "$PREFIX/lib" >> /etc/ld-musl-x86_64.path && \
  ln -s /usr/include/x86_64-linux-gnu/asm /usr/include/x86_64-linux-musl/asm && \
  ln -s /usr/include/asm-generic /usr/include/x86_64-linux-musl/asm-generic && \
  ln -s /usr/include/linux /usr/include/x86_64-linux-musl/linux

RUN curl -sSL http://zlib.net/zlib-$ZLIB_VER.tar.gz | tar xz && \
  cd zlib-$ZLIB_VER && \
  CC="musl-gcc -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" ./configure --static --prefix=$PREFIX && \
  make -j$(nproc) && make install && \
  cd .. && rm -rf zlib-$ZLIB_VER

# Build openssl (used in curl and pq)
# Would like to use zlib here, but can't seem to get it to work properly
# TODO: fix so that it works
RUN curl -sSL http://www.openssl.org/source/openssl-$SSL_VER.tar.gz | tar xz && \
  cd openssl-$SSL_VER && \
  ./Configure no-zlib no-shared -fPIC --prefix=$PREFIX --openssldir=$PREFIX/ssl linux-x86_64 && \
  env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null && \
  make -j$(nproc) && make install && \
  cd .. && rm -rf openssl-$SSL_VER

# Build curl (needs with-zlib and all this stuff to allow https)
# curl_LDFLAGS needed on stretch to avoid fPIC errors - though not sure from what
RUN curl -sSL https://curl.haxx.se/download/curl-$CURL_VER.tar.gz | tar xz && \
  cd curl-$CURL_VER && \
  CC="musl-gcc -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" ./configure \
  --enable-shared=no --with-zlib --enable-static=ssl --enable-optimize --prefix=$PREFIX \
  --with-ca-path=/etc/ssl/certs/ --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt --without-ca-fallback && \
  make -j$(nproc) curl_LDFLAGS="-all-static" && make install && \
  cd .. && rm -rf curl-$CURL_VER

ENV PATH=$PREFIX/bin:$PATH \
  PKG_CONFIG_ALLOW_CROSS=true \
  PKG_CONFIG_ALL_STATIC=true \
  PQ_LIB_STATIC_X86_64_UNKNOWN_LINUX_MUSL=true \
  PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
  OPENSSL_STATIC=true \
  OPENSSL_DIR=$PREFIX \
  SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  SSL_CERT_DIR=/etc/ssl/certs \
  LIBZ_SYS_STATIC=1
