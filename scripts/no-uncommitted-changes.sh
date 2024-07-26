#!/bin/sh

set -o errexit
set -o nounset

if [ -n "$(git status --porcelain)" ]
then
  echo "ERROR: There are uncommitted changes" 1>&2
  git diff
  exit 1
fi
