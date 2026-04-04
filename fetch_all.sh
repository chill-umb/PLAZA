#!/bin/bash

git submodule add https://github.com/chill-umb/rocksdb_plaza.git lib/rocksdb
git submodule add https://github.com/chill-umb/Tectonic.git lib/tectonic
git submodule update --init --force

cd lib/rocksdb
git submodule add https://github.com/chill-umb/zenfs_plaza.git plugin/zenfs
git submodule update --init --force
