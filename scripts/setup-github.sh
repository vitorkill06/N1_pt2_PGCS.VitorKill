#!/usr/bin/env bash
# Configura repositório, proteção da main, par de revisão e environments.
# Pré-requisitos: gh CLI autenticado (gh auth login) como o dono do repositório.
# Uso: ./scripts/setup-github.sh <dono> <repo> <usuario_do_par_de_revisao>
set -euo pipefail
OWNER="${1:?dono}"; REPO="${2:?repo}"; PAR="${3:?usuario do par de revisão}"
FULL="$OWNER/$REPO"

# 2) Repositório público (acessível para verificação). Se já existir (vazio), apenas envia o primeiro commit.
if gh repo view "$FULL" >/dev/null 2>&1; then
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$FULL.git"
  git push -u origin main   # primeiro push: a proteção ainda não está ativa
else
  gh repo create "$FULL" --public --source=. --remote=origin --push
fi
gh repo edit "$FULL" --visibility public --accept-visibility-change-consequences

# 4) Par de revisão com acesso de escrita
gh api -X PUT "repos/$FULL/collaborators/$PAR" -f permission=push

# 3) Proteção da main: sem push direto, PR + 1 aprovação + CI verde (vale para admins)
gh api -X PUT "repos/$FULL/branches/main/protection" --input - <<JSON
{
  "required_status_checks": {"strict": true, "contexts": ["ci"]},
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": false,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON

# 5) Environments: staging (livre) e production (com você como revisor obrigatório)
MEU_ID=$(gh api "users/$OWNER" --jq .id)
gh api -X PUT "repos/$FULL/environments/staging" >/dev/null
gh api -X PUT "repos/$FULL/environments/production" --input - <<JSON >/dev/null
{
  "reviewers": [{"type": "User", "id": $MEU_ID}],
  "deployment_branch_policy": {"protected_branches": true, "custom_branch_policies": false}
}
JSON
echo "Configuração concluída para $FULL"
