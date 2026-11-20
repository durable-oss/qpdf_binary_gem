# syntax=docker/dockerfile:1
#
# Builds a fully static qpdf executable against musl libc.
#
# zlib, libjpeg-turbo, OpenSSL, libstdc++ and musl are all linked in, so the
# result runs on any Linux kernel of the matching architecture with no shared
# libraries installed. bin/build-binaries drives this file; run it rather than
# calling docker directly, since it supplies the pinned version and checksum.

ARG ALPINE_IMAGE=alpine:3.22@sha256:49340b346798875b5592e5d420241f2f9cfba5f47e62ebb1446a1b34734e898f

FROM ${ALPINE_IMAGE} AS build

ARG QPDF_VERSION
ARG QPDF_SOURCE_SHA256

RUN apk add --no-cache \
      build-base \
      ca-certificates \
      cmake \
      curl \
      libjpeg-turbo-dev \
      libjpeg-turbo-doc \
      libjpeg-turbo-static \
      openssl-dev \
      openssl-libs-static \
      samurai \
      zlib-dev \
      zlib-static

WORKDIR /src

RUN test -n "${QPDF_VERSION}" && test -n "${QPDF_SOURCE_SHA256}" \
 && curl --fail --silent --show-error --location \
      -o qpdf.tar.gz \
      "https://github.com/qpdf/qpdf/releases/download/v${QPDF_VERSION}/qpdf-${QPDF_VERSION}.tar.gz" \
 && echo "${QPDF_SOURCE_SHA256}  qpdf.tar.gz" | sha256sum -c - \
 && tar -xzf qpdf.tar.gz --strip-components=1 \
 && rm qpdf.tar.gz

# OpenSSL is the only crypto provider compiled in, so `qpdf --show-crypto`
# reports exactly one. qpdf's native crypto is meant for testing and is not
# hardened, so it is deliberately left out.
RUN cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_FIND_LIBRARY_SUFFIXES=.a \
      -DCMAKE_EXE_LINKER_FLAGS="-static -s" \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_STATIC_LIBS=ON \
      -DBUILD_DOC=OFF \
      -DUSE_IMPLICIT_CRYPTO=OFF \
      -DREQUIRE_CRYPTO_OPENSSL=ON \
      -DDEFAULT_CRYPTO=openssl \
      -DSTATIC_JPEG=ON \
      -DSTATIC_OPENSSL=ON \
 && cmake --build build --target qpdf

# Refuse to emit anything that is not genuinely static, then exercise the
# binary: report its version, round-trip AES-256 encryption through OpenSSL,
# decode a JPEG stream through libjpeg-turbo, and structurally check the
# results. The sample PDFs come from qpdf's own test suite.
#
# The license texts of everything linked into the binary are exported with it,
# so the gem can ship them.
RUN set -eux; \
    bin=build/qpdf/qpdf; \
    if readelf --program-headers "$bin" | grep -q INTERP; then \
      echo "error: $bin requests a dynamic loader" >&2; exit 1; \
    fi; \
    if readelf --dynamic "$bin" | grep -q NEEDED; then \
      echo "error: $bin depends on shared libraries:" >&2; \
      readelf --dynamic "$bin" | grep NEEDED >&2; exit 1; \
    fi; \
    "$bin" --version | head -n 1 | grep -qx "qpdf version ${QPDF_VERSION}"; \
    test "$("$bin" --show-crypto)" = "openssl"; \
    samples=qpdf/qtest/qpdf; \
    "$bin" --encrypt --user-password=u --owner-password=o --bits=256 -- \
      "$samples/minimal-1.pdf" /tmp/encrypted.pdf; \
    "$bin" --password=u --decrypt /tmp/encrypted.pdf /tmp/decrypted.pdf; \
    "$bin" --check /tmp/decrypted.pdf >/dev/null; \
    "$bin" --decode-level=all "$samples/jpeg-qstream.pdf" /tmp/decoded.pdf; \
    "$bin" --check /tmp/decoded.pdf >/dev/null; \
    mkdir -p /out/licenses; \
    cp "$bin" /out/qpdf; \
    apk info -v 2>/dev/null | sort > /out/BUILDINFO; \
    cp LICENSE.txt /out/licenses/qpdf-LICENSE.txt; \
    cp NOTICE.md /out/licenses/qpdf-NOTICE.md; \
    cp /usr/share/doc/libjpeg-turbo/LICENSE.md /out/licenses/libjpeg-turbo-LICENSE.md; \
    cp /usr/share/doc/libjpeg-turbo/README.ijg /out/licenses/libjpeg-turbo-README.ijg; \
    sed -n '/^  Copyright (C)/,/^\*\//p' /usr/include/zlib.h > /out/licenses/zlib-LICENSE.txt; \
    test -s /out/licenses/zlib-LICENSE.txt

FROM scratch AS export
COPY --from=build /out/ /
