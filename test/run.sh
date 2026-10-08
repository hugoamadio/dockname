#!/bin/sh
# Unit tests: fixed `docker ps` lines in, routes / config / page / JSON out. No Docker needed.
# Backticks below are Traefik rule syntax, not command substitution.
# shellcheck disable=SC2016
set -eu
cd "$(dirname "$0")/.."
fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1"; echo "  expected: $3"; echo "  got:      $2"; fail=1; fi; }

routes=$(DOCKNAME_RULES=test/rules.sed sh generator.sh plan < test/containers.tsv)
check "routes match expected-routes.txt" "$routes" "$(cat test/expected-routes.txt)"

plain=$(DOCKNAME_RULES=/nonexistent sh generator.sh plan < test/containers.tsv)
check "without rules, names stay default" "$(echo "$plain" | grep feat42 | cut -d'|' -f2)" "api-feat42.localhost"
check "compose default name -> service.project" "$(echo "$plain" | grep '^shop-api-1|' | cut -d'|' -f2)" "api.shop.localhost"
check "compose replica -> service-n.project" "$(echo "$plain" | grep '^shop-api-2|' | cut -d'|' -f2)" "api-2.shop.localhost"
check "port 80 preferred over others" "$(echo "$plain" | grep '^admin|' | cut -d'|' -f3)" "7002"
check "dockname.port picks the container port" "$(echo "$plain" | grep '^custom|' | cut -d'|' -f3)" "7101"
check "dockname.enable=false is skipped" "$(echo "$plain" | grep -c '^hidden|' || true)" "0"
check "localhost-only port is skipped" "$(echo "$plain" | grep -c '^my-db|' || true)" "0"
check "udp-only is skipped" "$(echo "$plain" | grep -c '^worker|' || true)" "0"

dup=$(printf 'a\t0.0.0.0:1->80/tcp\t\tsame\t\t\t\nb\t0.0.0.0:2->80/tcp\t\tsame\t\t\t\n' | sh generator.sh plan)
check "a host taken twice goes to the first container" "$dup" "a|same.localhost|1|a"

custom=$(printf 'web\t0.0.0.0:8081->80/tcp\t\t\t\t\t\n' | DOCKNAME_DOMAIN=example sh generator.sh plan)
check "DOCKNAME_DOMAIN" "$custom" "web|web.example|8081|web"

empty=$(sh generator.sh yaml < /dev/null)
check "empty config still has a router (valid for Traefik)" "$(echo "$empty" | grep -c 'Host(`dockname.localhost`)')" "1"
check "empty JSON" "$(sh generator.sh json < /dev/null)" "[]"

yaml=$(sh generator.sh yaml < test/expected-routes.txt)
check "multi-host rule" "$(echo "$yaml" | grep -c 'Host(`docs.localhost`) || Host(`docs.example.localhost`)')" "1"
check "upstream is the host port" "$(echo "$yaml" | grep -c 'http://host.docker.internal:7101')" "1"

xss=$(printf 'x|x.localhost|1|<script>\n' | sh generator.sh html)
check "dashboard escapes names" "$(echo "$xss" | grep -c '&lt;script&gt;')" "1"

if command -v python3 >/dev/null; then
  if sh generator.sh json < test/expected-routes.txt | python3 -m json.tool > /dev/null; then echo "ok   JSON parses"; else echo "FAIL JSON parses"; fail=1; fi
fi
exit $fail
