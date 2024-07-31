#!/bin/sh

set -o errexit
set -o nounset

if [ $# -lt 2 ]
then
  echo "Usage: $0 <url> <output> <reference>" 1>&2
  exit 1
fi

URL="$1"
OUTPUT="$2"
REFERENCE="$3"

if [ -d "$OUTPUT/.git" ]
then
  CURRENT_SHA="$(git -C "$OUTPUT" rev-parse HEAD)"
  if [ "$REFERENCE" = "$CURRENT_SHA" ]
  then
    echo "-- Already at $REFERENCE" 1>&2
    exit 0
  fi

  echo "-- Fetching from $OUTPUT" 1>&2
  MAIN_BRANCH="$(git -C "$OUTPUT" remote show origin | sed -n '/HEAD branch/s/.*: //p')"
  git -C "$OUTPUT" checkout "$MAIN_BRANCH"
  git -C "$OUTPUT" fetch
else
  echo "-- Cloning $URL into $OUTPUT" 1>&2
  git clone --progress "$URL" "$OUTPUT" \
    || (rm -rf "$OUTPUT" && exit 1)
fi

echo "-- Checking out $REFERENCE" 1>&2
git -C "$OUTPUT" checkout "$REFERENCE"
