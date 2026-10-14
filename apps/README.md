# Argo CD Applications

Kyle installs these into `openshift-gitops` (or wraps them in an app-of-apps).

Configured in the Applications:

* Git source: `https://github.com/tsisodia10/ai-grid-gitops.git`
* Hub destination: `https://kubernetes.default.svc` (local pirate cluster)
* Site destination:
  `https://cluster-proxy-addon-user.multicluster-engine.svc.cluster.local:9092/pirate2`

Still required before applying:

* `REPLACE_*` values in the Helm values for cluster-specific SWIM / gateway
  addresses

All child Applications use manual sync. Trigger sync after reviewing and pushing
changes to this repository.

Suggested sync order:

1. `00-hub-namespaces` / `00-site-namespaces`
2. `10-hub-enrollment`
3. Run `scripts/copy-secrets.sh` (hub, then site)
4. `20-hub-operator`, `21-hub-site`, `22-hub-gateway`
5. `20-site-model`, `21-site-operator`, `22-site-site`, `23-site-gateway`

Each Helm Application uses multi-source: OCI chart + values from this repo.
