#!/usr/bin/env bash

if [ $# != 2 ]; then
  echo usage $0 install_dir build_dir
  exit
fi

INSTALL_DIR=$(readlink -f "${1}")
SOURCE_DIR=$(readlink -f "${2}")

[ -e "${INSTALL_DIR}/lib" ] || mkdir -p "${INSTALL_DIR}/lib"

cd "${SOURCE_DIR}/project_copasi-build/copasi"; 
find . -type f -iname "*.a" -exec cp --parents {} "${INSTALL_DIR}/lib" \;

[ -e "${INSTALL_DIR}/include" ] || mkdir -p "${INSTALL_DIR}/include"

cd "${SOURCE_DIR}/project_copasi"; 
find copasi -type f -iname "*.h" -exec cp --parents {} "${INSTALL_DIR}/include" \;
