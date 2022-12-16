#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )"
PORT=7777

if [ -f "$DIR/.env" ]; then
  source $DIR/.env
  export GH_TOKEN
fi

rm -v /tmp/gh-*.json
firefox localhost:${PORT}/cgi-bin/liveMon.sh &
python3 -m http.server ${PORT} --directory $DIR/monitor --cgi
