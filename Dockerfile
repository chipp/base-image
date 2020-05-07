FROM rust:1.43.0-slim-buster

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

RUN curl -sSL http://www.openssl.org/source/openssl-$SSL_VER.tar.gz | tar xz && \
  cd openssl-$SSL_VER && \
  ./Configure no-zlib no-shared -fPIC --prefix=$PREFIX --openssldir=$PREFIX/ssl linux-x86_64 && \
  env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null && \
  make -j$(nproc) && make install && \
  cd .. && rm -rf openssl-$SSL_VER

RUN curl -sSL https://curl.haxx.se/download/curl-$CURL_VER.tar.gz | tar xz && \
  cd curl-$CURL_VER && \
  LIBS="-ldl" LDFLAGS="-L$PREFIX/lib" CPPFLAGS="-I$PREFIX/include" CFLAGS="-I$PREFIX/include" ./configure \
  --enable-shared=no --with-zlib --enable-static=ssl --with-ssl="$PREFIX" --enable-optimize --prefix=$PREFIX \
  --with-ca-path=/etc/ssl/certs/ --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt --without-ca-fallback \
  --disable-shared --disable-ldap --disable-sspi --without-librtmp --disable-ftp \
  --disable-file --disable-dict --disable-telnet --disable-tftp --disable-manual --disable-ldaps \
  --disable-dependency-tracking --disable-rtsp --disable-pop3  --disable-imap --disable-smtp \
  --disable-gopher --disable-smb --without-libidn --disable-proxy && \
  make -j$(nproc) curl_LDFLAGS="-all-static" && make install && $PREFIX/bin/curl --version && \
  cd .. && rm -rf curl-$CURL_VER

ENV PATH=$PREFIX/bin:$PATH \
  PKG_CONFIG_ALLOW_CROSS=true \
  PKG_CONFIG_ALL_STATIC=true \
  PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
  OPENSSL_STATIC=true \
  OPENSSL_DIR=$PREFIX \
  SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  SSL_CERT_DIR=/etc/ssl/certs \
  LIBZ_SYS_STATIC=1
