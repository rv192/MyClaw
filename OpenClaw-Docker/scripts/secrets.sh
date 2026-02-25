#!/usr/bin/env bash
set -euo pipefail

# OpenClaw secrets helper
# Stable entrypoint (recommended): /usr/local/bin/openclaw-secrets.sh
# Backing env file: /root/.secure/.env

ENV_FILE="/root/.secure/.env"

usage() {
  cat <<'EOF'
Usage:
  openclaw-secrets.sh read <KEY>
  openclaw-secrets.sh write <KEY> <VALUE>
  openclaw-secrets.sh delete <KEY>
  openclaw-secrets.sh list

Notes:
- Backing file: /root/.secure/.env
- list is masked; read prints the value only (no extra logs).
- VALUE must be single-line. For multiline secrets, store base64.
EOF
}

ensure_env_file() {
  mkdir -p "$(dirname "$ENV_FILE")"
  chmod 700 "$(dirname "$ENV_FILE")" || true
  if [[ ! -f "$ENV_FILE" ]]; then
    : > "$ENV_FILE"
  fi
  chmod 600 "$ENV_FILE" || true
}

validate_key() {
  local k="$1"
  if [[ ! "$k" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "Invalid key: $k" >&2
    exit 2
  fi
}

strip_outer_quotes() {
  # Best-effort: remove one layer of surrounding quotes.
  local v="$1"
  v="${v%\"}"; v="${v#\"}"
  v="${v%\'}"; v="${v#\'}"
  printf '%s' "$v"
}

read_key() {
  local key="$1"
  validate_key "$key"
  ensure_env_file

  # Take the last assignment to support overrides.
  local val=""
  val="$(
    awk -v k="$key" 'BEGIN{FS="="} $1==k {v=substr($0, index($0,"=")+1)} END{if (v!="") print v}' "$ENV_FILE" || true
  )"

  if [[ -z "$val" ]]; then
    exit 1
  fi

  strip_outer_quotes "$val"
}

needs_quotes() {
  local v="$1"
  # Quote if contains whitespace or '#'
  if [[ "$v" =~ [[:space:]] ]] || [[ "$v" == *#* ]]; then
    return 0
  fi
  return 1
}

write_key() {
  local key="$1"
  local value="$2"
  validate_key "$key"
  ensure_env_file

  if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
    echo "VALUE must be single-line. Consider base64 for multiline." >&2
    exit 2
  fi

  local out="$value"
  if needs_quotes "$value"; then
    # escape backslash and double-quote
    out="${out//\\/\\\\}"
    out="${out//\"/\\\"}"
    out="\"$out\""
  fi

  local tmp
  tmp="$(mktemp)"

  # Remove any existing key assignments (keep everything else, including comments).
  awk -v k="$key" 'BEGIN{FS="="} $1!=k {print $0}' "$ENV_FILE" > "$tmp"
  printf '%s=%s\n' "$key" "$out" >> "$tmp"

  cat "$tmp" > "$ENV_FILE"
  rm -f "$tmp"
  chmod 600 "$ENV_FILE" || true
}

delete_key() {
  local key="$1"
  validate_key "$key"
  ensure_env_file

  local tmp
  tmp="$(mktemp)"
  awk -v k="$key" 'BEGIN{FS="="} $1!=k {print $0}' "$ENV_FILE" > "$tmp"
  cat "$tmp" > "$ENV_FILE"
  rm -f "$tmp"
  chmod 600 "$ENV_FILE" || true
}

mask_value() {
  local v="$1"
  v="$(strip_outer_quotes "$v")"
  local n=${#v}

  if (( n == 0 )); then
    printf '%s' ''
  elif (( n <= 8 )); then
    printf '%s' '****'
  else
    printf '%s' "${v:0:4}****${v: -4}"
  fi
}

list_keys() {
  ensure_env_file

  # Print as KEY=masked (sorted by key). Skip blank lines / comments.
  awk 'BEGIN{FS="="}
    /^[[:space:]]*#/ {next}
    /^[[:space:]]*$/ {next}
    $0 ~ /=/ {k=$1; v=substr($0, index($0,"=")+1); print k"="v}
  ' "$ENV_FILE" \
  | sort \
  | while IFS='=' read -r k v; do
      if [[ "$k" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        printf '%s=%s\n' "$k" "$(mask_value "$v")"
      fi
    done
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    read)
      [[ $# -eq 2 ]] || { usage >&2; exit 2; }
      read_key "$2"
      ;;
    write)
      [[ $# -eq 3 ]] || { usage >&2; exit 2; }
      write_key "$2" "$3"
      ;;
    delete)
      [[ $# -eq 2 ]] || { usage >&2; exit 2; }
      delete_key "$2"
      ;;
    list)
      [[ $# -eq 1 ]] || { usage >&2; exit 2; }
      list_keys
      ;;
    -h|--help|help|'')
      usage
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
