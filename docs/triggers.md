# Triggers

Three escalating thresholds let you split paging from informational tickets:

| Severity  | Default | Macro |
|-----------|---------|-------|
| Warning   | < 30d   | `{$ZBX.LE.WARN.DAYS}` |
| High      | < 14d   | `{$ZBX.LE.HIGH.DAYS}` |
| Disaster  | < 7d    | `{$ZBX.LE.DISASTER.DAYS}` |

Recovery happens automatically on renewal — `expires_in_days` jumps back to
~90 and the trigger resolves.

## Optional informational triggers

You can extend the template to flag certificates that are still RSA when you
have migrated everything else to ECDSA, or vice versa, by adding a trigger
prototype on `letsencrypt.cert.key_type[{#DOMAIN}]` matching `RSA`.
