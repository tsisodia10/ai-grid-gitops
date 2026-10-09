# AI Grid GitOps (pirate)

Argo CD deploys [AI Grid Network](https://github.com/praxis-proxy/grid) v0.2.0
across two pirate OpenShift clusters: a **hub** (enrollment + consumer gateway)
and a **site** (provider gateway + mock model).


## Layout

```text
apps/                 Argo CD Applications (hub + site destinations)
hub/                  Hub cluster values and namespaces
site/                 Site cluster values, namespaces, and mock model
scripts/copy-secrets.sh   Copy CA / invite / SWIM key after enrollment
```

## What gets installed

| Cluster | Namespace | Chart / resource |
|---------|-----------|------------------|
| Hub | `grid-enrollment` | `grid-enrollment` 0.2.0 |
| Hub | `grid` | `grid-operator`, `grid-site`, `praxis-gateway` 0.2.0 |
| Site | `grid` | `grid-operator`, `grid-site`, `praxis-gateway` 0.2.0 |
| Site | `model` | Mock `Qwen/Qwen3-0.6B` (`vllm-vcr`) |

Images and charts come from `ghcr.io/praxis-proxy` at version `0.2.0`.

## Before first sync

1. Fill the `REPLACE_*` placeholders in every `values.yaml` and in `apps/*.yaml`
   (repo URL, cluster destinations, enrollment host, SWIM / gateway addresses).
2. Kyle installs the Applications from `apps/` (or an app-of-apps) into
   `openshift-gitops`, with permission to create CRDs, ClusterRoles, and the
   namespaces above on both clusters.
3. Sync hub enrollment first, then hub operator / site / gateway, then site
   after secrets are copied.

## Secrets (not in Git)

After hub enrollment is Ready:

```bash
# On hub: copy CA + hub invite into grid, create SWIM key
./scripts/copy-secrets.sh hub

# On site: copy CA + site-a invite + SWIM key into grid
./scripts/copy-secrets.sh site
```

Never commit `grid-ca-bundle`, invite tokens, or `grid-swim-key`.

## Validate

```bash
oc --context <hub> wait gridsite/grid-site-a \
  --for=jsonpath='{.status.phase}'=Active --timeout=10m

oc --context <hub> -n grid port-forward svc/grid-gateway 8080:8080
curl -sS -D - http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"Qwen/Qwen3-0.6B","messages":[{"role":"user","content":"ping"}],"max_tokens":16}'
```

Success includes response header `x-grid-provider-site: site-a`.

## Source

Based on [praxis-proxy/grid#323](https://github.com/praxis-proxy/grid/pull/323)
getting-started guide (hub + one site, SPIFFE, poll signals).
