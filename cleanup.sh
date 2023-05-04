pushd docker || exit
docker-compose down
for volume in $(docker volume ls -q)
do
  # Don't clean up the docker cache volume, as this likely has a bunch of large downloads we don't want to do again
  if [[ "${volume}" != "docker_dockercache" ]]
  then
    docker volume rm "${volume}"
  fi
done
popd || exit

kind delete cluster --name octopus