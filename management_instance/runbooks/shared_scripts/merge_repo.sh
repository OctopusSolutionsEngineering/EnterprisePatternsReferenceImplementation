CAC_PROTO=${cac_proto}
CAC_HOST=${cac_host}
CAC_ORG=${cac_org}
CAC_USERNAME=${cac_username}
CAC_PASSWORD=${cac_password}
NEW_REPO="${new_repo}"
TEMPLATE_REPO="${template_repo}"
PROJECT_DIR="${project_dir}"
BRANCH=main

# Replace these with some sensible values
git config --global user.email "octopus@octopus.com" 2>&1
git config --global user.name "Octopus Server" 2>&1

# Clone the template repo to test for a step template reference
mkdir template
pushd template
git clone $${CAC_PROTO}://$${CAC_USERNAME}:$${CAC_PASSWORD}@$${CAC_HOST}/$${CAC_ORG}/$${TEMPLATE_REPO}.git ./ 2>&1
if [[ $${BRANCH} -eq "main" || $${BRANCH} -eq "master" ]]
then
  git checkout $${BRANCH} 2>&1
else
  git checkout -b $${BRANCH} origin/$${BRANCH} 2>&1
fi

if grep -Fxq "ActionTemplates" "$${PROJECT_DIR}/deployment_process.ocl";
then
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

# Checkout the project branch, assuming "main" or "master" are already linked upstream
if [[ $${BRANCH} -eq "main" || $${BRANCH} -eq "master" ]]
then
  git checkout $${BRANCH} 2>&1
else
  git checkout -b $${BRANCH} origin/$${BRANCH} 2>&1
fi

if git merge --no-commit upstream-$${BRANCH} 2>&1;
then
    echo "Merge is able to be performed automatically, or no merge is required."
    git merge upstream-$${BRANCH} 2>&1

    # Test that some changes need to be pushed
    if ! git diff --quiet --exit-code @{upstream};
    then
      GIT_EDITOR=/bin/true git merge --continue 2>&1
      echo "Pushing merged changes."
      git push origin 2>&1
    else
      echo "No merge is required."
    fi
else
    >&2 echo "Template repo branch could not be automatically merged into project branch. This merge will need to be resolved manually."
    exit 1
fi