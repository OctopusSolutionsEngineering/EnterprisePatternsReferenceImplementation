# Getting Started

Set the `OCTOPUS_SERVER_BASE64_LICENSE` environment variable to a base 64 encoded copy of your Octopus license key. This
is passed through to the Octopus instances launched by Docker.

Ensure you have the [Octopus CLI](https://octopus.com/downloads/octopuscli) tool installed.

You will also need DockerHub credentials. You will be prompted to add the DockerHub username and password when initializing
the Octopus instances.

Start the Octopus and Git stack with:

```bash
./initdemo.sh
```

Shut the Octopus and Git stack down with:

```bash
./cleanup.sh
```

# Todo

Create environment for synchronizing. [DONE]
Scope runbooks to sync environment. [DONE]
Add unmanaged project deployment.
Add self-service project deployment.
Add tenants for managed spaces.
Link tenants to sample projects.
Test serialize and deploy.
Add CaC enabled projects.
Add merge runbooks.

Create development, test/production spaces.
Add sample project to development.
Use variable sets for database connection string.
Add promotion runbook.