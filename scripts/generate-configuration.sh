#!/bin/sh

set -o errexit
set -o nounset

if [ $# -lt 2 ]
then
  echo "Usage: $0 <directory> <base url>" 1>&2
  exit 1
fi

DIRECTORY="$1"
BASE_URL="$2"

TMP="$(mktemp -d)"
clean() { rm -rf "$TMP"; }
trap clean EXIT

# $1 = input.json
# $2 = property name
read_property() {
  jq --raw-output "select(.$2) | .$2" "$1"
}

# $1 = output.json
# $2 = path
# $3 = value
insert_string_property() {
  jq --raw-output "setpath(\"$2\" | split(\"|\"); \"$3\")" < "$1" > "$1.new"
  mv "$1.new" "$1"
}

# $1 = input.json
# $2 = property name
# $3 = property destination path
# $4 = output file
copy_string_property_if_present() {
  PROPERTY="$(read_property "$1" "$2")"
  if [ -n "$PROPERTY" ]
  then
    insert_string_property "$4" "$3" "$PROPERTY"
  fi
}

RESULT="$TMP/configuration.json"
jq --raw-output --null-input '$ARGS.named' --arg url "$BASE_URL" > "$RESULT"

find "$DIRECTORY" -name '*.json' -type f -depth 2 | while IFS= read -r collection
do

  NAMESPACE="$(basename "$(dirname "$collection")")"
  ID="$(basename "$collection" .json)"
  PAGES_CONFIGURATION_PREFIX="pages|$NAMESPACE/$ID"
  COLLECTIONS_CONFIGURATION_PREFIX="collections|$NAMESPACE/$ID"
  TYPE="$(jq --raw-output '.type' "$collection")"

  echo "-- Analyzing collection $collection ($TYPE)" 1>&2

  if [ "$TYPE" = "git" ]
  then
    URL="$(read_property "$collection" "url")"
    REFERENCE="$(read_property "$collection" "reference")"
    COLLECTION_WEBSITE="$URL/tree/$REFERENCE"
    insert_string_property "$RESULT" "$PAGES_CONFIGURATION_PREFIX|website" "$COLLECTION_WEBSITE"
    copy_string_property_if_present "$collection" "description" "$PAGES_CONFIGURATION_PREFIX|description" "$RESULT"
    copy_string_property_if_present "$collection" "base" "$COLLECTIONS_CONFIGURATION_PREFIX|base" "$RESULT"
    insert_string_property "$RESULT" "$COLLECTIONS_CONFIGURATION_PREFIX|path" "./schemas/$NAMESPACE/$ID"
  else
    echo "error: Unknown collection type: $TYPE" 1>&2
    exit 1
  fi
done

find "$DIRECTORY" -name '*.json' -type f -depth 1 | while IFS= read -r manifest
do
  echo "-- Analyzing manifest $manifest" 1>&2
  NAMESPACE="$(basename "$manifest" .json)"
  PAGES_CONFIGURATION_PREFIX="pages|$NAMESPACE"

  copy_string_property_if_present "$manifest" "title" "$PAGES_CONFIGURATION_PREFIX|title" "$RESULT"
  copy_string_property_if_present "$manifest" "description" "$PAGES_CONFIGURATION_PREFIX|description" "$RESULT"
  copy_string_property_if_present "$manifest" "website" "$PAGES_CONFIGURATION_PREFIX|website" "$RESULT"
  copy_string_property_if_present "$manifest" "github" "$PAGES_CONFIGURATION_PREFIX|github" "$RESULT"
  copy_string_property_if_present "$manifest" "email" "$PAGES_CONFIGURATION_PREFIX|email" "$RESULT"
done

cat "$RESULT"
rm "$RESULT"
