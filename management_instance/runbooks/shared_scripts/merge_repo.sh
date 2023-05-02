CAC_PROTO=${cac_proto}
CAC_HOST=${cac_host}
CAC_ORG=${cac_org}
CAC_USERNAME=${cac_username}
CAC_PASSWORD=${cac_password}
NEW_REPO="${new_repo}"
TEMPLATE_REPO="${template_repo}"
BRANCH=main

# Replace these with some sensible values
git config --global user.email "octopus@octopus.com" 2>&1
git config --global user.name "Octopus Server" 2>&1

# Clone the template repo to test for a step template reference
mkdir template
pushd template
git clone $${TEMPLATE_REPO} ./ 2>&1
git checkout -b $BRANCH origin/$${BRANCH} 2>&1
grep -Fxq "ActionTemplates" "$${PROJECT_DIR}/deployment_process.ocl"
if [[ $? == "0" ]]; then
  >&2 echo "Template repo references a step template. Step templates can not be merged across spaces or instances."
  exit 1
fi
popd

# Merge the template changes
git clone $${CAC_PROTO}://$${CAC_USERNAME}:$${CAC_PASSWORD}@$${CAC_HOST}/$${CAC_ORG}/$${NEW_REPO}.git 2>&1
cd $${NEW_REPO}
git remote add upstream $${CAC_PROTO}://$${CAC_USERNAME}:$${CAC_PASSWORD}@$${CAC_HOST}/$${CAC_ORG}/$${TEMPLATE_REPO}.git 2>&1
git fetch --all 2>&1
git checkout -b upstream-$${BRANCH} upstream/$${BRANCH} 2>&1
git checkout -b $${BRANCH} origin/$${BRANCH} 2>&1
git merge --no-commit upstream-$${BRANCH} 2>&1

if [[ $? == "0" ]]; then
    git merge upstream-$${BRANCH} 2>&1

    # Test that a merge is being performed
    git merge HEAD &> /dev/null
    if [[ $? -ne 0 ]]; then
      GIT_EDITOR=/bin/true git merge --continue 2>&1
      git push origin 2>&1
    fi
else
    >&2 echo "Template repo branch could not be automatically merged into project branch. This merge will need to be resolved manually."
    exit 1
fi