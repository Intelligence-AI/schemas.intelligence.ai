#!/bin/sh

set -o errexit
set -o nounset

if [ $# -lt 3 ]
then
  echo "Usage: $0 <directory> <fetch directory> <output>" 1>&2
  exit 1
fi

DIRECTORY="$1"
FETCH_DIRECTORY="$2"
OUTPUT="$3"

slugify() {
  echo "$1" | sed 's/[@:./%]/-/g' | sed -E 's/-+/-/g' | tr "[:upper:]" "[:lower:]"
}

echo "-- Installing collection schemas from $DIRECTORY into $OUTPUT" 1>&2

find "$DIRECTORY" -name '*.json' -type f -depth 2 | while IFS= read -r collection
do
  NAMESPACE="$(basename "$(dirname "$collection")")"
  ID="$(basename "$collection" .json)"
  COLLECTION_OUTPUT="$OUTPUT/$NAMESPACE/$ID"

  echo "-- Installing $collection into $COLLECTION_OUTPUT" 1>&2

  cd "$FETCH_DIRECTORY/$NAMESPACE/$ID"

  # Includes
  jq --raw-output --compact-output '.include[]' "$collection" | \
    while IFS= read -r includes
  do
    INCLUDE_PATH="$(echo "$includes" | jq --raw-output '.path')"
    echo "-- Installing include path $INCLUDE_PATH" 1>&2
    find "$INCLUDE_PATH" -name '*.json' -type f | while IFS= read -r schema
    do
      SCHEMA_PATH="${schema%.*}"
      SCHEMA_SLUG="$(slugify "$SCHEMA_PATH")"
      SCHEMA_OUTPUT="$COLLECTION_OUTPUT/$SCHEMA_SLUG.json"
      mkdir -p "$COLLECTION_OUTPUT"
      # TODO: Rebase the schema identifiers here before copying
      install -v -m 0644 "$schema" "$SCHEMA_OUTPUT"
    done
  done

  # Excludes
  jq --raw-output --compact-output '.exclude // [] | .[]' "$collection" | \
    while IFS= read -r excludes
  do
    EXCLUDE_PATH="$(echo "$excludes" | jq --raw-output '.path')"
    echo "-- Excluding path $EXCLUDE_PATH" 1>&2
    find "$EXCLUDE_PATH" -name '*.json' -type f | while IFS= read -r schema
    do
      SCHEMA_PATH="${schema%.*}"
      SCHEMA_SLUG="$(slugify "$SCHEMA_PATH")"
      SCHEMA_OUTPUT="$COLLECTION_OUTPUT/$SCHEMA_SLUG.json"
      rm -rf "$SCHEMA_OUTPUT"
    done
  done

  cd - > /dev/null
done
