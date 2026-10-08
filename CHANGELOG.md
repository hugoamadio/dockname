# Changelog

## 0.1.0 - 2026-10-08

First public release.

- `name.localhost` for every container with a published TCP port, no labels needed.
- Compose-aware names: `<service>.<project>.localhost`, `<service>-<n>.<project>.localhost` for replicas.
- Labels: `dockname.host`, `dockname.port`, `dockname.enable`.
- Naming rules with `rules.sed` (`sed -E`), for patterns such as one copy of an app per branch.
- Dashboard at `dockname.localhost`, routes as JSON at `dockname.localhost/routes.json`.
- Routes are rewritten only when they change, so Traefik doesn't reload on unrelated events.
- `DOCKNAME_HTTP_PORT`, `DOCKNAME_DOMAIN`, `DOCKNAME_PREFERRED_PORTS`.
