echo "##octopus[stdout-verbose]"
git config --global user.email "octopus@octopus.com" 2>&1
git config --global user.name "Octopus Server" 2>&1
git config --global pull.rebase false 2>&1

# The webhook proxy will set this variable with the details of the PR
PR="#{Webhook.Pr.Body}"

mkdir clone
pushd clone

BASEREPO=$(echo "$PR" | jq -r '.baseRepo')

# Gitea thinks it is hosted on "localhost", but we need to access it via the hostname "gitea"
git clone "${BASEREPO/localhost/gitea}" . 2>&1

# Pull the branches and attempt a merge
git checkout -b $(echo "$PR" | jq -r '.headRef') $(echo "$PR" | jq -r '.baseRef') 2>&1
git pull origin $(echo "$PR" | jq -r '.headRef') 2>&1
git checkout $(echo "$PR" | jq -r '.baseRef') 2>&1
git merge --no-ff --no-edit $(echo "$PR" | jq -r '.headRef') 2>&1

popd

# Run the PR check
pushd check
STATUS=$(node check.js "../clone/.octopus/project")
RESULT=$?
popd

echo "##octopus[stdout-default]"

echo "${STATUS}"

echo "##octopus[stdout-verbose]"

rm -rf clone

if [[ $RESULT == "0" ]]
then
  curl \
    --silent \
    -u 'octopus:Password01!' \
    -X POST "http://gitea:3000/api/v1/repos/octopuscac/hello_world_cac/statuses/$(echo "$PR" | jq -r '.headSha')" \
    -H "Content-Type: application/json" \
    -d "{\"context\":\"octopus\",\"description\":\"${STATUS//\"/\\\"}\",\"state\":\"success\",\"target_url\":\"http://localhost:18080\"}"
else
  curl \
    --silent \
    -u 'octopus:Password01!' \
    -X POST "http://gitea:3000/api/v1/repos/octopuscac/hello_world_cac/statuses/$(echo "$PR" | jq -r '.headSha')" \
    -H "Content-Type: application/json" \
    -d "{\"context\":\"octopus\",\"description\":\"${STATUS//\"/\\\"}\",\"state\":\"failure\",\"target_url\":\"http://localhost:18080\"}"
fi
