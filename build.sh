#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )"

source $DIR/monitor/cgi-bin/marketMon.sh

build="$DIR/build"

clean() {
  rm -rf "$build"
  mkdir -p "$build"
}

build() {
  html="${build}/index.html"
  page "${html}" | sed "s|/monitor\.css|monitor\.css|g" > "${html}"
  cp -v "${DIR}/monitor/monitor.css" "${build}"
  echo "monitor built to ${html}!"
}

clean
build
