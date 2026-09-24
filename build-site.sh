#!/bin/sh
# Builds the website into site/: challenges.json, the VM image (site/vm) and a copy of daily/ for local testing.
# Needs root for the image, or run unprivileged: unshare --map-auto --map-root-user sh build-site.sh
set -eu
cd "$(dirname "$0")"
python3 gen/build.py challenges build/lab >/dev/null
cp build/lab/challenges.json site/challenges.json
[ -x build/venv/bin/python ] || { python3 -m venv build/venv && build/venv/bin/pip install -q zstandard; }
PYTHON=$PWD/build/venv/bin/python sh image/build.sh site/vm
cp image/bios/*.bin site/vm/
rm -rf site/daily && cp -r daily site/daily
