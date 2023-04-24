pushd docker
docker-compose down
docker volume rm $(docker volume ls -q)
popd