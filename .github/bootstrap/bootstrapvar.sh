#!/usr/bin/env bash
set -euo pipefail
GH_REPO="chrisdhsc-boop/azure-sre-sandpit"
LOC=uksouth
SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SA="sttfstateda4bcdca"          # globally unique, lowercase

# 5. Repo variables (IDs, not secrets). The env-level AZURE_CLIENT_ID overrides the repo-level one,
#    so jobs in environment 'sandpit' get the apply identity and everything else gets plan.
gh variable set AZURE_TENANT_ID       --repo "$GH_REPO" --body "$TENANT_ID"
gh variable set AZURE_SUBSCRIPTION_ID --repo "$GH_REPO" --body "$SUB_ID"
#gh variable set AZURE_CLIENT_ID       --repo "$GH_REPO" --body "$PLAN_APP"
#gh variable set AZURE_CLIENT_ID       --repo "$GH_REPO" --env sandpit --body "$APPLY_APP"
gh variable set TF_STATE_SA           --repo "$GH_REPO" --body "$SA"
