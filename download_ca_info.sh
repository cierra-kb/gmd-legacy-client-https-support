#!/usr/bin/env bash

tmp_name=$(mktemp)

wget -O $tmp_name https://curl.se/ca/cacert-2025-12-02.pem

chk=($(sha256sum $tmp_name))
chk="${chk[0]}"

if [ $chk != "f1407d974c5ed87d544bd931a278232e13925177e239fca370619aba63c757b4" ]; then
    echo "Corrupted"
    exit 1
fi

xxd -i -n CAInfoBlob $tmp_name > src/cainfo.c
