# See https://gitea.com/jolheiser/gitea-webhook/src/branch/main/events/pull_request.json
# for a sample webhook body.

echo "##octopus[stdout-verbose]"
git config --global user.email "octopus@octopus.com" 2>&1
git config --global user.name "Octopus Server" 2>&1
git config --global pull.rebase false 2>&1

# The webhook proxy will set this variable with the details of the PR
PR=$(get_octopusvariable "Webhook.Pr.Body")

mkdir clone
pushd clone

BASEREPO=$(echo "$PR" | jq -r '.base.repo.clone_url')

# Gitea thinks it is hosted on "localhost", but we need to access it via the hostname "gitea"
git clone "${BASEREPO/localhost/gitea}" . 2>&1

cp check.js ..

# Pull the branches and attempt a merge
git checkout -b "$(echo "$PR" | jq -r '.head.ref')" "$(echo "$PR" | jq -r '.base.ref')" 2>&1
git pull origin "$(echo "$PR" | jq -r '.head.ref')" 2>&1
git checkout "$(echo "$PR" | jq -r '.base.ref')" 2>&1
git merge --no-ff --no-edit "$(echo "$PR" | jq -r '.head.ref')" 2>&1

popd

# Run the PR check
STATUS=$(node check.js "../clone/.octopus/project")
RESULT=$?

echo "##octopus[stdout-default]"

echo "${STATUS}"

echo "##octopus[stdout-verbose]"

rm -rf clone

if [[ $RESULT == "0" ]]
then
  curl \
    --silent \
    -u 'octopus:Password01!' \
    -X POST "http://gitea:3000/api/v1/repos/$(echo "$PR" | jq -r '.base.repo.full_name')/statuses/$(echo "$PR" | jq -r '.head.sha')" \
    -H "Content-Type: application/json" \
    -d "{\"context\":\"octopus\",\"description\":\"${STATUS//\"/\\\"}\",\"state\":\"success\",\"target_url\":\"http://localhost:18080\"}"
else
  curl \
    --silent \
    -u 'octopus:Password01!' \
    -X POST "http://gitea:3000/api/v1/repos/$(echo "$PR" | jq -r '.base.repo.full_name')/statuses/$(echo "$PR" | jq -r '.head.sha')" \
    -H "Content-Type: application/json" \
    -d "{\"context\":\"octopus\",\"description\":\"${STATUS//\"/\\\"}\",\"state\":\"failure\",\"target_url\":\"http://localhost:18080\"}"
fi
