#!/bin/sh

set -eu

MIMALLOC_VERSION=2.1.2

cd /tmp

apk upgrade --no-cache

apk add --no-cache \
  alpine-sdk \
  cmake

curl -f -L --retry 5 https://github.com/microsoft/mimalloc/archive/refs/tags/v$MIMALLOC_VERSION.tar.gz | tar xz --strip-components=1

patch -p1 < mimalloc.diff

cmake \
  -Bout \
  -DCMAKE_BUILD_TYPE=Release \
  -DMI_BUILD_OBJECT=OFF \
  -DMI_BUILD_TESTS=OFF \
  .

cmake --build out

mv out/libmimalloc.so* /usr/lib

for libc_path in $(find /usr -name libc.a); do
  {
    echo "CREATE libc.a"
    echo "ADDLIB $libc_path"
    echo "DELETE aligned_alloc.lo calloc.lo donate.lo free.lo libc_calloc.lo lite_malloc.lo malloc.lo malloc_usable_size.lo memalign.lo posix_memalign.lo realloc.lo reallocarray.lo valloc.lo"
    echo "ADDLIB out/libmimalloc.a"
    echo "SAVE"
  } | ar -M
  mv libc.a $libc_path
done

rm -rf /tmp/*
