#!/bin/sh

set -o errexit
set -o nounset

if [ $# -lt 2 ]
then
  echo "Usage: $0 <directory> <output>" 1>&2
  exit 1
fi

DIRECTORY="$1"
OUTPUT="$2"

echo "-- Fetching collections from $DIRECTORY into $OUTPUT" 1>&2

find "$DIRECTORY" -name '*.json' -type f -depth 2 | while IFS= read -r collection
do
  NAMESPACE="$(basename "$(dirname "$collection")")"
  ID="$(basename "$collection" .json)"
  COLLECTION_OUTPUT="$OUTPUT/$NAMESPACE/$ID"
  mkdir -p "$(dirname "$COLLECTION_OUTPUT")"
  TYPE="$(jq --raw-output '.type' "$collection")"
  URL="$(jq --raw-output '.url' "$collection")"

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
