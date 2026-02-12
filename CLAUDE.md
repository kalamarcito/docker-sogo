# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker container for SOGo groupware, built from source with custom patches. Deployed on a Synology NAS via Komodo, authenticating against Synology's LDAP. The `custom` branch contains NAS-specific configuration; upstream is `sonroyaalmerol/docker-sogo`.

## Common Commands

```bash
# Build image locally
docker build --build-arg SOGO_VERSION=5.10.0 -t sogo:latest .

# Start/stop the stack (postgres + memcached + sogo)
docker compose up -d
docker compose down

# Logs
docker compose logs -f sogo

# Test HTTP (expect 302 redirect to login)
curl -v http://localhost:8080/SOGo

# Run config-generator tests
cd config-generator && go test -v ./...

# Shell into running container
docker compose exec sogo /bin/bash

# Inside container: check process status
supervisorctl status
```

## Architecture

### Multi-Stage Docker Build

1. **tool_plus_builder** (Go) — Compiles `sogo-tool-plus` (REST API + CLI for calendar subscriptions and session management)
2. **generator_builder** (Go) — Compiles `config-generator` (YAML → OpenStep plist converter); runs unit tests during build
3. **builder** (Debian) — Compiles SOGo + SOPE from source tarballs, applies patches from `patches/`
4. **Final image** (Debian slim) — Runtime with Apache2, supervisord, cron, and the compiled binaries

### Config Pipeline (startup sequence)

```
compose starts container
  → entrypoint-wrapper.sh: envsubst on YAML templates (injects LDAP_HOST, etc.)
    → entrypoint.sh: sets PUID/PGID, creates dirs, runs config-generator
      → config-generator: merges all *.yaml files alphabetically → /etc/sogo/sogo.conf (plist)
        → supervisord starts: sogod, apache, sogo-tool-plus, cron, log tailer
```

Config templates live in `sogo-config/` and are mounted read-only to `/etc/sogo/sogo.conf.d.templates`. After envsubst, the processed files land in `/etc/sogo/sogo.conf.d/`, where config-generator picks them up.

### Process Supervision

The container runs 5 processes under supervisord (`scripts/supervisord.conf`):
- **sogo** — Main daemon via `sogod.sh` (runs as user `sogo`, foreground with `-WONoDetach YES`)
- **apache** — Reverse proxy to sogod
- **sogo_tool_plus** — REST API on port 8008 for calendar/session operations
- **sogo_logs** — Tails `/var/log/sogo/sogo.log` to container stdout
- **crond** — Scheduled tasks

### Patches

`patches/SOGoUserManager.m` and `patches/SOGoDAVAuthenticator.m` are copied over SOGo source during build to add JWT and Bearer token authentication support.

## Critical Constraints

- **Memcached is required** — Without it, SOGo cannot maintain sessions and users get infinite login redirects. Never disable `SOGoMemcachedHost` in production.
- **Container memory limit is 512MB** — Set in compose.yaml to protect the NAS. `WOWorkersCount` and `SxVMemLimit` must fit within this.
- **LDAP env vars are injected via Komodo** — `LDAP_HOST`, `LDAP_BASE_DN`, `LDAP_BIND_DN`, `LDAP_BIND_PASSWORD` are empty in compose.yaml and populated at deploy time.
- **SOGoXSRFValidationEnabled is disabled** — Was causing login loops; investigate before re-enabling.

## Key Config Files

- `sogo-config/sogo.yaml` — Main SOGo config template (env vars substituted at runtime)
- `compose.yaml` — Docker Compose with postgres, memcached, sogo services
- `init-db/init.sql` — PostgreSQL permission grants (SOGo auto-creates its own tables)
- `scripts/entrypoint.sh` — Container initialization logic
- `scripts/sogod.sh` — SOGo daemon launcher (sets LD_PRELOAD for libssl)

## Go Modules

**config-generator/** — Merges multiple YAML files via `deepMergeMaps()`, encodes to OpenStep plist with `howett.net/plist`. Files sorted alphabetically, so numbered prefixes (e.g. `01-db.yaml`) control merge order. Has unit tests in `generator_test.go`.

**sogo-tool-plus/** — Database operations tool. Two modes: `server` (HTTP on :8008) and `cli`. Actions: `cal-subscribe-user`, `cal-subscribe-all`, `expire-sessions-creation`. Reads DB URLs from SOGo plist config. Supports both PostgreSQL and MySQL with automatic SQL parameter normalization (`?` → `$N`).

## Debugging Checklist

1. Check envsubst output: `docker compose exec sogo cat /etc/sogo/sogo.conf.d/sogo.yaml`
2. Check generated plist: `docker compose exec sogo cat /etc/sogo/sogo.conf`
3. Check supervisor: `docker compose exec sogo supervisorctl status`
4. Check SOGo logs: `docker compose exec sogo cat /var/log/sogo/sogo.log`
5. Check LDAP connectivity (debug flags are enabled in current config)
6. Verify memcached is reachable from sogo container
