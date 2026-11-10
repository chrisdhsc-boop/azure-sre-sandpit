#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash on Windows: stop it rewriting /subscriptions/... scopes
GH_REPO="chrisdhsc-boop/azure-sre-sandpit"
LOC=uksouth
SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SA="sttfstateda4bcdca"          # globally unique, lowercase

# 1. Terraform state storage: TLS 1.2, no public blobs, no shared keys, versioning on
az storage account create -n "$SA" -g rg-tfstate -l "$LOC" --sku Standard_LRS --kind StorageV2 \
  --min-tls-version TLS1_2 --allow-blob-public-access false \
  --allow-shared-key-access false --https-only true
az storage account blob-service-properties update -g rg-tfstate --account-name "$SA" \
  --enable-versioning true --enable-delete-retention true --delete-retention-days 7
SA_ID=$(az storage account show -n "$SA" -g rg-tfstate --query id -o tsv)

ME=$(az ad signed-in-user show --query id -o tsv)
az role assignment create --assignee-object-id "$ME" --assignee-principal-type User \
  --role "Storage Blob Data Contributor" --scope "$SA_ID"
echo "Waiting 60s for role propagation..."; sleep 60
az storage container create -n tfstate --account-name "$SA" --auth-mode login

# 2. Two app registrations + service principals
make_app () {
  local app_id
  app_id=$(az ad app create --display-name "$1" --query appId -o tsv)
  az ad sp create --id "$app_id" >/dev/null
  echo "$app_id"
}
PLAN_APP=$(make_app gh-sandpit-plan)
APPLY_APP=$(make_app gh-sandpit-apply)

# 3. Federated credentials: GitHub's OIDC token subject decides which identity a job gets
fic () {
  az ad app federated-credential create --id "$1" --parameters \
  "{\"name\":\"$2\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"$3\",\"audiences\":[\"api://AzureADTokenExchange\"]}" >/dev/null
}
fic "$PLAN_APP"  gh-pr   "repo:$GH_REPO:pull_request"         # PR plans
fic "$PLAN_APP"  gh-main "repo:$GH_REPO:ref:refs/heads/main"  # smoke test, nightly drift
fic "$APPLY_APP" gh-env  "repo:$GH_REPO:environment:sandpit"  # only jobs in the approved env

# 4. Roles: plan reads everything; apply writes only to rg-sandpit; both use state
PLAN_SP=$(az ad sp show --id "$PLAN_APP" --query id -o tsv)
APPLY_SP=$(az ad sp show --id "$APPLY_APP" --query id -o tsv)
RG_ID=$(az group show -n rg-sandpit --query id -o tsv)
az role assignment create --assignee-object-id "$PLAN_SP" --assignee-principal-type ServicePrincipal \
  --role Reader --scope "/subscriptions/$SUB_ID"
az role assignment create --assignee-object-id "$APPLY_SP" --assignee-principal-type ServicePrincipal \
  --role Contributor --scope "$RG_ID"
for sp in "$PLAN_SP" "$APPLY_SP"; do
  az role assignment create --assignee-object-id "$sp" --assignee-principal-type ServicePrincipal \
    --role "Storage Blob Data Contributor" --scope "$SA_ID"
done

# 5. Repo variables (IDs, not secrets). The env-level AZURE_CLIENT_ID overrides the repo-level one,
#    so jobs in environment 'sandpit' get the apply identity and everything else gets plan.
gh variable set AZURE_TENANT_ID       --repo "$GH_REPO" --body "$TENANT_ID"
gh variable set AZURE_SUBSCRIPTION_ID --repo "$GH_REPO" --body "$SUB_ID"
gh variable set AZURE_CLIENT_ID       --repo "$GH_REPO" --body "$PLAN_APP"
gh variable set AZURE_CLIENT_ID       --repo "$GH_REPO" --env sandpit --body "$APPLY_APP"
gh variable set TF_STATE_SA           --repo "$GH_REPO" --body "$SA"

echo "Done. State account: $SA | plan app: $PLAN_APP | apply app: $APPLY_APP"