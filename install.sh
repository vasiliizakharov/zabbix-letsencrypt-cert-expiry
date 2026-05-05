#!/usr/bin/env bash
# Idempotent installer for zabbix-letsencrypt-cert-expiry.
# Author: Vasilii Zakharov <vasiliiazakharov@gmail.com>

set -euo pipefail

if ! id zabbix >/dev/null 2>&1; then
  echo "ERROR: user 'zabbix' not found." >&2
  exit 1
fi

CONF_DIR=/etc/zabbix/zabbix_agentd.d
SCRIPT_DIR=/usr/local/bin
SELF=$(cd "$(dirname "$0")" && pwd)

install -d -m 0755 "$CONF_DIR"
install -m 0644 "$SELF/userparameter_letsencrypt.conf" -t "$CONF_DIR/"
install -m 0755 "$SELF/scripts/zbx_letsencrypt.sh" -t "$SCRIPT_DIR/"

# Grant zabbix user read access via ACL if available.
LE_DIR="${ZBX_LE_LIVE_DIR:-/etc/letsencrypt}"
if command -v setfacl >/dev/null 2>&1 && [[ -d "$LE_DIR" ]]; then
  setfacl -R -m u:zabbix:rx "$LE_DIR/live" "$LE_DIR/archive" 2>/dev/null || true
  setfacl -R -d -m u:zabbix:rx "$LE_DIR/live" "$LE_DIR/archive" 2>/dev/null || true
  echo "Granted zabbix r-x ACL on $LE_DIR/{live,archive}"
fi

if systemctl restart zabbix-agent2 2>/dev/null; then
  echo "Restarted zabbix-agent2"
elif systemctl restart zabbix-agent 2>/dev/null; then
  echo "Restarted zabbix-agent"
fi

echo "Installed."
