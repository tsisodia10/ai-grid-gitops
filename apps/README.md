# Argo CD Applications

Kyle installs these into `openshift-gitops` (or wraps them in an app-of-apps).

Replace before apply:

- `REPLACE_GITOPS_REPO_URL` — this repository HTTPS URL
- `REPLACE_HUB_DESTINATION` — hub cluster name or API URL known to Argo
- `REPLACE_SITE_DESTINATION` — site (second pirate) cluster name or API URL

Suggested sync order:

1. `00-hub-namespaces` / `00-site-namespaces`
2. `10-hub-enrollment`
3. Run `scripts/copy-secrets.sh` (hub, then site)
4. `20-hub-operator`, `21-hub-site`, `22-hub-gateway`
5. `20-site-model`, `21-site-operator`, `22-site-site`, `23-site-gateway`

Each Helm Application uses multi-source: OCI chart + values from this repo.
