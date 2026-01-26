#!/bin/bash
set -euo pipefail

errors=0

log_error() {
  echo "[architecture-check] ERROR: $1"
  errors=1
}

log_warning() {
  echo "[architecture-check] WARN: $1"
}

feature_dirs() {
  find lib/features -maxdepth 1 -mindepth 1 -type d | sort
}

check_layer_imports() {
  local layer="$1"
  while IFS= read -r feature_dir; do
    local feature
    feature=$(basename "$feature_dir")
    local target_dir="$feature_dir/$layer"
    if [[ ! -d "$target_dir" ]]; then
      continue
    fi
    local matches
    matches=$(grep -r "import .*/data/" "$target_dir" --include "*.dart" -n 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      log_error "Layer '$layer' in feature '$feature' imports from a data package"
      echo "$matches"
    fi
  done < <(feature_dirs)
}

check_firestore_types() {
  local matches
  matches=$(grep -rE "DocumentSnapshot|Timestamp" lib --include "*.dart" -n 2>/dev/null | grep -v "/data/" || true)
  if [[ -n "$matches" ]]; then
    log_error "Firestore types referenced outside lib/**/data/**"
    echo "$matches"
  fi
}

check_feature_mix() {
  while IFS= read -r feature_dir; do
    local feature
    feature=$(basename "$feature_dir")
    local dir="$feature_dir/presentation"
    if [[ ! -d "$dir" ]]; then
      continue
    fi
    local has_bloc
    local has_cubit
    has_bloc=$(find "$dir" -type d -name bloc -print -quit || true)
    has_cubit=$(find "$dir" -type d -name cubit -print -quit || true)
    if [[ -n "$has_bloc" && -n "$has_cubit" ]]; then
      log_error "Feature '$feature' mixes Bloc and Cubit under presentation"
    fi
  done < <(feature_dirs)
}

check_layer_imports presentation
check_layer_imports domain
check_firestore_types
check_feature_mix

if [[ $errors -ne 0 ]]; then
  exit 1
fi
