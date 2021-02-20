OUTPUT = /musl
GCC_VER = 7.3.0
MUSL_VER = 1.1.24
DL_CMD = curl -C - -L -o

COMMON_CONFIG += CFLAGS="-g0 -Os" CXXFLAGS="-g0 -Os" LDFLAGS="-s"

COMMON_CONFIG += --disable-nls
GCC_CONFIG += --enable-languages=c,c++
GCC_CONFIG += --disable-libquadmath --disable-decimal-float
GCC_CONFIG += --disable-multilib

COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)=
