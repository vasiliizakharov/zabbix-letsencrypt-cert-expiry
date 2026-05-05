#!/usr/bin/env bash
# Inspect Let's Encrypt / generic PEM certificates for Zabbix.
# Usage:
#   zbx_letsencrypt.sh discovery
#   zbx_letsencrypt.sh expires <domain>
#   zbx_letsencrypt.sh issuer <domain>
#   zbx_letsencrypt.sh san_count <domain>
#   zbx_letsencrypt.sh sigalg <domain>
#   zbx_letsencrypt.sh keytype <domain>
# Author: Vasilii Zakharov <vasiliiazakharov@gmail.com>

set -euo pipefail

LIVE_DIR="${ZBX_LE_LIVE_DIR:-/etc/letsencrypt/live}"

mode="${1:-}"
domain="${2:-}"

cert_path() {
  local d="$1"
  if [[ -f "$LIVE_DIR/$d/fullchain.pem" ]]; then
    echo "$LIVE_DIR/$d/fullchain.pem"
  elif [[ -f "$LIVE_DIR/$d/cert.pem" ]]; then
    echo "$LIVE_DIR/$d/cert.pem"
  else
    return 1
  fi
}

discovery() {
  first=1
  printf '{"data":['
  if [[ -d "$LIVE_DIR" ]]; then
    while IFS= read -r -d '' d; do
      name=$(basename "$d")
      [[ "$name" == "README" ]] && continue
      cert_path "$name" >/dev/null 2>&1 || continue
      if [[ $first -eq 1 ]]; then first=0; else printf ','; fi
      printf '{"{#DOMAIN}":"%s"}' "$name"
    done < <(find "$LIVE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  fi
  printf ']}\n'
}

expires() {
  local p
  p=$(cert_path "$domain") || { echo -1; return; }
  local end_epoch now days
  end_epoch=$(date -d "$(openssl x509 -in "$p" -noout -enddate | cut -d= -f2)" +%s 2>/dev/null || echo 0)
  now=$(date +%s)
  if [[ "$end_epoch" -le 0 ]]; then echo -1; return; fi
  days=$(( (end_epoch - now) / 86400 ))
  echo "$days"
}

issuer() {
  local p
  p=$(cert_path "$domain") || { echo "unknown"; return; }
  openssl x509 -in "$p" -noout -issuer 2>/dev/null \
    | sed -E 's/.*CN ?= ?([^,\/]+).*/\1/' | head -1
}

san_count() {
  local p
  p=$(cert_path "$domain") || { echo 0; return; }
  openssl x509 -in "$p" -noout -ext subjectAltName 2>/dev/null \
    | tr ',' '\n' | grep -c 'DNS:' || echo 0
}

sigalg() {
  local p
  p=$(cert_path "$domain") || { echo "unknown"; return; }
  openssl x509 -in "$p" -noout -text 2>/dev/null \
    | awk -F': ' '/Signature Algorithm/ {print $2; exit}'
}

keytype() {
  local p
  p=$(cert_path "$domain") || { echo "unknown"; return; }
  local txt
  txt=$(openssl x509 -in "$p" -noout -text 2>/dev/null)
  if echo "$txt" | grep -q 'Public Key Algorithm: id-ecPublicKey'; then
    echo "ECDSA"
  elif echo "$txt" | grep -q 'Public Key Algorithm: rsaEncryption'; then
    echo "RSA"
  else
    echo "unknown"
  fi
}

case "$mode" in
  discovery)  discovery ;;
  expires)    expires ;;
  issuer)     issuer ;;
  san_count)  san_count ;;
  sigalg)     sigalg ;;
  keytype)    keytype ;;
  *) echo "usage: $0 {discovery|expires|issuer|san_count|sigalg|keytype} [domain]" >&2; exit 2 ;;
esac
