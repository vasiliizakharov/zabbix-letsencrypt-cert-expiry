#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/zabbix/zabbix_agentd.d/userparameter_letsencrypt.conf
rm -f /usr/local/bin/zbx_letsencrypt.sh
systemctl restart zabbix-agent2 2>/dev/null || systemctl restart zabbix-agent 2>/dev/null || true
echo "Uninstalled. ACLs on /etc/letsencrypt left intact — remove with 'setfacl -b' if desired."
