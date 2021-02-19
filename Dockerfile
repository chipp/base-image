FROM debian:buster-slim

ENV RUST_VERSION=1.50.0

ARG TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64

RUN apt-get update && apt-get install -y \
  curl \
  xutils-dev \
  unzip \
  xz-utils \
  bzip2 \
  patch \
  build-essential \
  file \
  pkg-config \
  ca-certificates \
  --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

COPY config.mak config.mak

RUN curl -sSL -o musl.zip https://github.com/richfelker/musl-cross-make/archive/v0.9.9.zip && \
  echo "6cbe2f6ce92e7f8f3973786aaf0b990d0db380c0e0fc419a7d516df5bb03c891  musl.zip" | sha256sum -c -; \
  unzip musl.zip && mv musl-cross-make-0.9.9 musl-cross-make && cd musl-cross-make && \
  mv ../config.mak ./ && \
  TARGET=$TARGET make -j$(nproc) install > /dev/null && \
  cd .. && rm -rf musl-cross-make

ENV SSL_VER="1.0.2q" \
  CURL_VER="7.64.1" \
  ZLIB_VER="1.2.11"

ENV PREFIX=/musl/$TARGET \
  PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
  LD_LIBRARY_PATH=$PREFIX \
  PATH=/musl/bin:$PATH

ENV TARGET_CC=/musl/bin/$TARGET-gcc \
  TARGET_CXX=/musl/bin/$TARGET-g++ \
  TARGET_C_INCLUDE_PATH=$PREFIX/include/

ENV CC=$TARGET_CC \
  C_INCLUDE_PATH=$TARGET_C_INCLUDE_PATH

RUN curl -sSL http://zlib.net/zlib-$ZLIB_VER.tar.gz | tar xz && \
  cd zlib-$ZLIB_VER && \
  CC="$CC -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" \
  CHOST=arm ./configure --static --prefix=$PREFIX && \
  make -j$(nproc) && make install && \
  cd .. && rm -rf zlib-$ZLIB_VER

RUN curl -sSL http://www.openssl.org/source/openssl-$SSL_VER.tar.gz | tar xz && \
  cd openssl-$SSL_VER && \
  CC=gcc ./Configure no-zlib no-shared -fPIC --cross-compile-prefix=$TARGET- --prefix=$PREFIX --openssldir=$PREFIX/ssl $OPENSSL_ARCH && \
  env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null && \
  make -j$(nproc) && make install_sw && \
  cd .. && rm -rf openssl-$SSL_VER

RUN curl -sSL https://curl.haxx.se/download/curl-$CURL_VER.tar.gz | tar xz && \
  cd curl-$CURL_VER && \
  LIBS="-ldl" LDFLAGS="-L$PREFIX/lib" CPPFLAGS="-I$PREFIX/include" CFLAGS="-I$PREFIX/include" ./configure \
  --enable-shared=no --with-zlib --enable-static=ssl --with-ssl="$PREFIX" --enable-optimize --prefix=$PREFIX \
  --with-ca-path=/etc/ssl/certs/ --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt --without-ca-fallback \
  --disable-shared --disable-ldap --disable-sspi --without-librtmp --disable-ftp \
  --disable-file --disable-dict --disable-telnet --disable-tftp --disable-manual --disable-ldaps \
  --disable-dependency-tracking --disable-rtsp --disable-pop3  --disable-imap --disable-smtp \
  --disable-gopher --disable-smb --without-libidn --disable-proxy --host armv7 && \
  make -j$(nproc) curl_LDFLAGS="-all-static" && make install && \
  cd .. && rm -rf curl-$CURL_VER

ENV PATH=/root/.cargo/bin:$PATH

RUN curl -O https://static.rust-lang.org/rustup/archive/1.23.1/x86_64-unknown-linux-gnu/rustup-init; \
    echo "ed7773edaf1d289656bdec2aacad12413b38ad0193fff54b2231f5140a4b07c5 *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host x86_64-unknown-linux-gnu; \
    rm rustup-init; \
    rustup target add $TARGET

RUN echo "[build]\ntarget = \"$TARGET\"\n\n\
[target.$TARGET]\nlinker = \"$TARGET-gcc\"\n" > /root/.cargo/config

ENV OPENSSL_STATIC=1 \
  OPENSSL_DIR=$PREFIX \
  OPENSSL_INCLUDE_DIR=$PREFIX/include/ \
  DEP_OPENSSL_INCLUDE=$PREFIX/include/ \
  OPENSSL_LIB_DIR=$PREFIX/lib/ \
  LIBZ_SYS_STATIC=1 \
  PKG_CONFIG_ALLOW_CROSS=true \
  PKG_CONFIG_ALL_STATIC=true \
  PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
  SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  SSL_CERT_DIR=/etc/ssl/certs