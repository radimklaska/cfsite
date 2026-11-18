#!/usr/bin/env bash
# Create a least-privilege Cloudflare deploy token for one GitHub repo and store it
# (plus the account ID) as that repo's Actions secrets. The token value is never printed.
#
#   scripts/create-deploy-token.sh <github-repo-name>
#
# Explained on https://cfsite.klaska.net/hosting/#deploy-token.
# Needs in ~/.env: CF_API_TOKEN (account-owned token allowed to create account tokens)
# and CLOUDFLARE_ACCOUNT_ID. Needs gh logged in as the repo owner.
# GH_OWNER (default radimklaska) and CF_ZONE (default klaska.net) override the defaults.
# Permissions:
#   zone ($CF_ZONE): Zone Read, Workers Routes Write
#   account:         Workers Scripts Write, Account Settings Read
# Expires one year from today; renew by re-running (it creates a new token: delete the
# old one in the dashboard, Manage Account > Account API Tokens).
set -euo pipefail

repo=${1:?usage: $0 <github-repo-name>}
gh_repo="${GH_OWNER:-radimklaska}/$repo"
zone_name=${CF_ZONE:-klaska.net}

set -a; . ~/.env; set +a
: "${CF_API_TOKEN:?missing in ~/.env}" "${CLOUDFLARE_ACCOUNT_ID:?missing in ~/.env}"
api=https://api.cloudflare.com/client/v4
auth="Authorization: Bearer $CF_API_TOKEN"
acc=$CLOUDFLARE_ACCOUNT_ID

gh repo view "$gh_repo" --json name > /dev/null # fail fast on a wrong repo name

zone=$(curl -fsS -H "$auth" "$api/zones?name=$zone_name" | jq -r '.result[0].id')
expires=$(date -u -d '+1 year' +%Y-%m-%dT23:59:59Z)

body=$(jq -n --arg acc "$acc" --arg zone "$zone" --arg name "$repo GitHub Actions deploy" --arg exp "$expires" '{
  name: $name, expires_on: $exp,
  policies: [
    {effect: "allow",
     permission_groups: [{id: "c8fed203ed3043cba015a93ad1616f1f"},   # Zone Read
                         {id: "28f4b596e7d643029c524985477ae49a"}],  # Workers Routes Write
     resources: {("com.cloudflare.api.account.zone." + $zone): "*"}},
    {effect: "allow",
     permission_groups: [{id: "e086da7e2179491d91ee5f35b3ca210a"},   # Workers Scripts Write
                         {id: "c1fde68c7bcc44588cbb6ddbc16d6480"}],  # Account Settings Read
     resources: {("com.cloudflare.api.account." + $acc): "*"}}
  ]}')

resp=$(curl -sS -X POST -H "$auth" -H 'Content-Type: application/json' "$api/accounts/$acc/tokens" -d "$body")
if [ "$(jq -r .success <<<"$resp")" != true ]; then
  jq -c '.errors' <<<"$resp" >&2
  exit 1
fi
jq -c '{created: .result.name, id: .result.id, expires_on: .result.expires_on}' <<<"$resp"

jq -r .result.value <<<"$resp" | gh secret set CLOUDFLARE_API_TOKEN -R "$gh_repo"
printf '%s' "$acc" | gh secret set CLOUDFLARE_ACCOUNT_ID -R "$gh_repo"

new=$(jq -r .result.value <<<"$resp")
unset resp
curl -fsS -H "Authorization: Bearer $new" "$api/accounts/$acc/tokens/verify" | jq -c '{verify: .result.status}'
unset new
gh secret list -R "$gh_repo"
