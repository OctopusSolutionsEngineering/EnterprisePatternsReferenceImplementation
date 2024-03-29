echo "Verify Docker is Running"
echo "##octopus[stdout-verbose]"
docker info
if ! docker info
then
  echo "Docker is not running. Check that Docker is installed and the daemon is running."
  exit 1
fi
echo "##octopus[stdout-default]"

echo "Pulling the Cypress image"
echo "##octopus[stdout-verbose]"
docker pull octopussamples/cypress-included:12.8.1
echo "##octopus[stdout-default]"

cd octopub-cypress

docker run --rm -e "NO_COLOR=1" -e "CYPRESS_BASE_URL=https://#{Octopus.Action[Create Web App].Output.HostName}/" -v $PWD:/e2e -w /e2e octopussamples/cypress-included:12.8.1 2>&1

RESULT=$?
if [[ -f mochawesome.html ]]
then
  docker run --rm --entrypoint="/usr/local/bin/inline-assets" -v $PWD:/e2e -w /e2e octopussamples/cypress-included:12.8.1 mochawesome.html selfcontained.html 2>&1
  new_octopusartifact "${PWD}/selfcontained.html" "selfcontained.html"
fi
if [[ -d cypress/screenshots ]]
then
  docker run --rm --entrypoint="/usr/bin/zip" -v $PWD:/e2e -w /e2e octopussamples/cypress-included:12.8.1 -r screenshots.zip cypress/screenshots 2>&1
  new_octopusartifact "${PWD}/screenshots.zip" "screenshots.zip"
fi

if [[ -d cypress/videos ]]
then
  docker run --rm --entrypoint="/usr/bin/zip" -v $PWD:/e2e -w /e2e octopussamples/cypress-included:12.8.1 -r videos.zip cypress/videos 2>&1
  new_octopusartifact "${PWD}/videos.zip" "videos.zip"
fi

exit ${RESULT}