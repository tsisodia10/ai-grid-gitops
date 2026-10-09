#!/usr/bin/env bash
# Copy enrollment secrets into grid. Never commit the output.
#
# Usage:
#   HUB_CONTEXT=<hub> SITE_CONTEXT=<site> ./scripts/copy-secrets.sh hub
#   HUB_CONTEXT=<hub> SITE_CONTEXT=<site> ./scripts/copy-secrets.sh site
set -euo pipefail

MODE="${1:-}"
HUB_CONTEXT="${HUB_CONTEXT:-}"
SITE_CONTEXT="${SITE_CONTEXT:-}"

if [[ -z "$MODE" || -z "$HUB_CONTEXT" ]]; then
  echo "Usage: HUB_CONTEXT=<hub> [SITE_CONTEXT=<site>] $0 hub|site" >&2
  exit 1
fi

oc_hub() { oc --context "$HUB_CONTEXT" "$@"; }
oc_site() {
  if [[ -z "$SITE_CONTEXT" ]]; then
    echo "SITE_CONTEXT is required for mode=site" >&2
    exit 1
  fi
  oc --context "$SITE_CONTEXT" "$@"
}

case "$MODE" in
  hub)
    oc_hub get ns grid >/dev/null 2>&1 || oc_hub create ns grid
    oc_hub -n grid-enrollment get secret grid-ca-bundle -o jsonpath='{.data.ca\.crt}' | base64 -d \
      | oc_hub -n grid create secret generic grid-ca-bundle --from-file=ca.crt=/dev/stdin --dry-run=client -o yaml \
      | oc_hub apply -f -
    oc_hub -n grid-enrollment get secret grid-invite-hub -o jsonpath='{.data.token}' | base64 -d \
      | oc_hub -n grid create secret generic grid-invite-hub --from-file=token=/dev/stdin --dry-run=client -o yaml \
      | oc_hub apply -f -
    oc_hub -n grid label secret grid-invite-hub grid.praxis.fast/site=hub --overwrite
    if ! oc_hub -n grid get secret grid-swim-key >/dev/null 2>&1; then
      head -c 32 /dev/urandom \
        | oc_hub -n grid create secret generic grid-swim-key --from-file=key=/dev/stdin
    fi
    echo "Hub secrets ready in grid/"
    ;;
  site)
    oc_site get ns grid >/dev/null 2>&1 || oc_site create ns grid
    oc_hub -n grid-enrollment get secret grid-ca-bundle -o jsonpath='{.data.ca\.crt}' | base64 -d \
      | oc_site -n grid create secret generic grid-ca-bundle --from-file=ca.crt=/dev/stdin --dry-run=client -o yaml \
      | oc_site apply -f -
    oc_hub -n grid-enrollment get secret grid-invite-site-a -o jsonpath='{.data.token}' | base64 -d \
      | oc_site -n grid create secret generic grid-invite-site-a --from-file=token=/dev/stdin --dry-run=client -o yaml \
      | oc_site apply -f -
    oc_site -n grid label secret grid-invite-site-a grid.praxis.fast/site=site-a --overwrite
    oc_hub -n grid get secret grid-swim-key -o jsonpath='{.data.key}' | base64 -d \
      | oc_site -n grid create secret generic grid-swim-key --from-file=key=/dev/stdin --dry-run=client -o yaml \
      | oc_site apply -f -
    echo "Site secrets ready in grid/"
    ;;
  *)
    echo "Unknown mode: $MODE (use hub or site)" >&2
    exit 1
    ;;
esac
