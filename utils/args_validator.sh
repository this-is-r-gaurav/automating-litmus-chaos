#!/usr/bin/env bash
REQUIRED=1
NOT_REQUIRED=-1
function required_or_default() {
  case $2 in
  "$REQUIRED")
    if [[ -z "$3" ]]; then
      printf "%s required\n\n" "$1"
      exit 1
    fi
    ;;
  "$NOT_REQUIRED")
    # $4 == verbose
    if [[ -n "$4" ]]; then
      echo "Considering Default for $1: $3"
    fi
    ;;

  esac
}
