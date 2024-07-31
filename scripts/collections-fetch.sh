#!/bin/sh

set -o errexit
set -o nounset

if [ $# -lt 3 ]
then
  echo "Usage: $0 <directory> <output> <schemas>" 1>&2
  exit 1
fi

DIRECTORY="$1"
OUTPUT="$2"
SCHEMAS="$3"

echo "-- Fetching collections from $DIRECTORY into $OUTPUT" 1>&2

find "$DIRECTORY" -mindepth 2 -maxdepth 2 -name '*.json' -type f | while IFS= read -r collection
do
  NAMESPACE="$(basename "$(dirname "$collection")")"
  ID="$(basename "$collection" .json)"
  COLLECTION_OUTPUT="$OUTPUT/$NAMESPACE/$ID"
  mkdir -p "$(dirname "$COLLECTION_OUTPUT")"
  TYPE="$(jq --raw-output '.type' "$collection")"
  URL="$(jq --raw-output '.url' "$collection")"

  HASH_PATH="$SCHEMAS/$NAMESPACE/$ID/.collection.md5"
  COLLECTION_HASH="$(md5sum "$collection" | cut -d ' ' -f 1)"
  if [ -f "$HASH_PATH" ]
  then
    echo "-- Found collection hash marker: $HASH_PATH" 1>&2
    CURRENT_HASH="$(tr -d '\n\r' < "$HASH_PATH")"
    if [ "$CURRENT_HASH" = "$COLLECTION_HASH" ]
    then
      echo "-- Hashes match. Skipping fetch" 1>&2
      continue
    fi
  fi

  echo "-- Fetching $collection ($TYPE) into $COLLECTION_OUTPUT" 1>&2
  if [ "$TYPE" = "git" ]
  then
    REFERENCE="$(jq --raw-output '.reference' "$collection")"
    ./scripts/collections-fetch-git.sh "$URL" "$COLLECTION_OUTPUT" "$REFERENCE"
  else
    echo "error: Unknown collection type: $TYPE" 1>&2
    exit 1
  fi
done
