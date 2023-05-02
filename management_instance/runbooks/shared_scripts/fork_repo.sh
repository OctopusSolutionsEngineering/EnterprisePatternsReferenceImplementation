# All of this is to essentially fork a repo within the same organisation

CAC_URL=${cac_url}
CAC_ORG=${cac_org}
CAC_PASSWORD=${cac_password}
NEW_REPO="${new_repo}"
TEMPLATE_REPO="${template_repo}"
BRANCH=main

# Attempt to view the template repo
curl \
  --output /dev/null \
  --silent \
  --fail \
  -u "octopus:$${CAC_PASSWORD}" \
  -X GET \
  "$${CAC_URL}/$${CAC_ORG}/$${TEMPLATE_REPO}.git"

if [[ $? != "0" ]]; then
    >&2 echo "Could not find the template repo at $${CAC_URL}/$${CAC_ORG}/$${TEMPLATE_REPO}.git"
    exit 1
fi

echo "##octopus[stdout-verbose]"

# Attempt to view the new repo
curl \
  --output /dev/null \
  --silent \
  --fail \
  -u "octopus:Password01!" \
  -X GET \
  "$${CAC_URL}/$${CAC_ORG}/$${NEW_REPO}.git"

if [[ $? != "0" ]]; then
    # If we could not view the repo, assume it needs to be created.
    curl \
      --output /dev/null \
      --silent \
      -u "octopus:Password01!" \
      -X POST \
      "$${CAC_URL}/api/v1/org/$${CAC_ORG}/repos" \
      -H "content-type: application/json" \
      -H "accept: application/json" \
      --data "{\"name\":\"$${NEW_REPO}\"}"

fi

# Clone the repo
git clone $${CAC_URL}/$${CAC_ORG}/$${NEW_REPO}.git 2>&1

# Enter the repo.
cd $${NEW_REPO}

# Link the template repo as a new remote.
git remote add upstream $${CAC_URL}/$${CAC_ORG}/$${TEMPLATE_REPO}.git 2>&1

# Fetch all the code from the upstream remots.
git fetch --all 2>&1

# Test to see if the remote branch already exists.
git show-branch remotes/origin/$${BRANCH} 2>&1

if [ $? == "0" ]; then
  # Checkout the remote branch.
  git checkout -b $${BRANCH} origin/$${BRANCH} 2>&1

  # If the .octopus directory exists, assume this repo has already been prepared.
  if [ -d ".octopus" ]; then
      echo "##octopus[stdout-default]"
      echo "The repo has already been forked."
      exit 0
  fi
fi

# Create a new branch representing the forked main branch.
git checkout -b $${BRANCH} 2>&1

# Hard reset it to the template main branch.
git reset --hard upstream/$${BRANCH} 2>&1

# Push the changes.
git push origin $${BRANCH} 2>&1

echo "##octopus[stdout-default]"
echo "Repo was forked from $${CAC_URL}/$${CAC_ORG}/$${TEMPLATE_REPO} to $${CAC_URL}/$${CAC_ORG}/$${NEW_REPO}"