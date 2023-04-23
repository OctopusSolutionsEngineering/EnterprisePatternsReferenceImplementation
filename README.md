# Stack Initialization

Start the Octopus and Git stack with:

```bash
docker-compose up
```

Create the initial gitea user called `octopus` with the password `Password01!` with the command:

```bash
docker exec -it gitea su git bash -c "gitea admin user create --admin --username octopus --password Password01! --email me@example.com"
```

Create a new organization called `octopuscac` with the command:

```bash
curl \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/admin/users/octopus/orgs" \
  -H "Content-Type: application/json" \
  -H "accept: application/json" \
  --data '{"username": "octopuscac"}'
```

Create a new repositories with the commands:

```bash
curl \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/org/octopuscac/repos" \
  -H "content-type: application/json" \
  -H "accept: application/json" \
  --data '{"name":"europe-product-service"}'
```

```bash
curl \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/org/octopuscac/repos" \
  -H "content-type: application/json" \
  -H "accept: application/json" \
  --data '{"name":"europe-frontend"}'
```

```bash
curl \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/org/octopuscac/repos" \
  -H "content-type: application/json" \
  -H "accept: application/json" \
  --data '{"name":"america-product-service"}'
```

```bash
curl \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/org/octopuscac/repos" \
  -H "content-type: application/json" \
  -H "accept: application/json" \
  --data '{"name":"america-frontend"}'
```

# Octopus Initialization

Add the git credentials for the Gitea server started with Docker Compose:

```bash
pushd shared/gitcreds/gitea/pgbackend
terraform init -reconfigure
terraform apply -auto-approve
popd
```

Add the standard set of environments:

```bash
pushd shared/environments/dev_test_prod/pgbackend
terraform init -reconfigure
terraform apply -auto-approve
popd
```

Add the common feeds:

```bash
pushd shared/feeds/maven/pgbackend
terraform init -reconfigure
terraform apply -auto-approve
popd
```

```bash
pushd shared/feeds/dockerhub/pgbackend
terraform init -reconfigure
terraform apply -auto-approve
popd
```

# Cleanup

Stop Docker compose with `CTRL-C`.

Shutdown containers with:

```bash
docker-compose down
```

Remove volumes with:

```bash
docker volume rm $(docker volume ls -q)
```