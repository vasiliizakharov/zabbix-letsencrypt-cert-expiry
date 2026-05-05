# zabbix-letsencrypt-cert-expiry

Zabbix 7.0 LLD-based template that discovers every certificate under
`/etc/letsencrypt/live/` and watches days-to-expiry, issuer, key type, and
signature algorithm. No external probes — works on air-gapped hosts.

## What it monitors

- LLD of all domains in `/etc/letsencrypt/live/*`
- Days until expiry (per domain)
- Issuer common name (e.g. "E1", "R3", "Let's Encrypt R10")
- Subject Alternative Names count
- Signature algorithm (e.g. ecdsa-with-SHA384)
- Key type (RSA / ECDSA)

## Requirements

- Zabbix agent 5.0+
- `openssl`, `find`, GNU coreutils
- The agent process needs read access to `*.pem` files. The installer adds
  ACLs (`setfacl -m u:zabbix:rx`) to `/etc/letsencrypt/{live,archive}` if
  `setfacl` is present.

## Install

```sh
sudo ./install.sh
```

If your live directory is not the default, set the env var on the agent
before running install:

```sh
ZBX_LE_LIVE_DIR=/srv/letsencrypt/live sudo ./install.sh
```

Then import `template/template.yaml` in the Zabbix UI.

## Items

- `letsencrypt.cert.discovery` (LLD)
- `letsencrypt.cert.expires_in_days[domain]`
- `letsencrypt.cert.issuer[domain]`
- `letsencrypt.cert.subject_alt_names_count[domain]`
- `letsencrypt.cert.signature_algorithm[domain]`
- `letsencrypt.cert.key_type[domain]`

## Triggers

See [docs/triggers.md](docs/triggers.md). Three escalating severities at 30 / 14 / 7 days.

## Macros

| Macro | Default |
|-------|---------|
| `{$ZBX.LE.WARN.DAYS}` | 30 |
| `{$ZBX.LE.HIGH.DAYS}` | 14 |
| `{$ZBX.LE.DISASTER.DAYS}` | 7 |

## Notes

- The script also handles non-Let's-Encrypt PEM directories. Just point
  `ZBX_LE_LIVE_DIR` at any directory containing `<name>/fullchain.pem` (or
  `cert.pem`).
- For wildcard certs, the SAN count covers every name in the SAN extension,
  so a single `*.example.com + example.com` cert reports `2`.

## License

MIT — see [LICENSE](LICENSE).
