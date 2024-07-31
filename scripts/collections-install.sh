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

find "$DIRECTORY" -mindepth 2 -maxdepth 2 -name '*.json' -type f | while IFS= read -r collection
do
  NAMESPACE="$(basename "$(dirname "$collection")")"
  ID="$(basename "$collection" .json)"
  COLLECTION_OUTPUT="$OUTPUT/$NAMESPACE/$ID"

  HASH_PATH="$COLLECTION_OUTPUT/.collection.md5"
  COLLECTION_HASH="$(md5sum "$collection" | cut -d ' ' -f 1)"
  if [ -f "$HASH_PATH" ]
  then
    echo "-- Found collection hash marker: $HASH_PATH" 1>&2
    CURRENT_HASH="$(tr -d '\n\r' < "$HASH_PATH")"
    if [ "$CURRENT_HASH" = "$COLLECTION_HASH" ]
    then
      echo "-- Hashes match. Skipping install" 1>&2
      continue
    fi
  fi

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

  echo "$COLLECTION_HASH" > "$HASH_PATH"
done
