# Getting Started

Start the Octopus and Git stack with the following command. Any missing tools or undefined environment variables will
be reported before the setup can start:

```bash
./initdemo.sh
```

Shut the Octopus and Git stack down with:

```bash
./cleanup.sh
```

# Scenarios
* Disable steps in downstream project
* Move project to new group
* Rename project
* Different tenants
* Different variables (e.g. database creds)
* Different environments
  * With step/variable scoping
* 

# Todo

* Create environment for synchronizing. [DONE]
* Scope runbooks to sync environment. [DONE]
* Add managed project deployment. [DONE]
* Add unmanaged project deployment. [DONE]
* Add self-service project deployment.
  * Add management instance shared variables.
  * deploy a "run a runbook" step
* Add tenants for managed spaces. [DONE]
* Link tenants to sample projects. [DONE]
* Add tenant specific octopus variables. [DONE]
* Test serialize and deploy. [DONE]
* Add CaC enabled projects. [DONE]
  * Allow CaC url to be overridden. [DONE]
  * Ignore versioning strategy for CaC enabled projects.[DONE]
* Add merge runbooks. [DONE]
* Add ocl check during merge.
* Add one-to-many project deployments. [DONE]
* Add merge all runbook
* Add list downstream projects runbook [DONE]
* Add merge conflict check runbook [DONE]
* Status runbook should show repos with upstream changes, behind downstream, equal, and merge conflict
* Use sensible defines for ignoring changes and remove the prompts [DONE]
* Run create space and compose resources before fork or clone
* Add runbook variable scoping
* Fix k8s template to work with octopub
* Add get k8s logs runbook
* Add delete k8s pods runbook
* Add curl smoke test runbook
* Add slack incident channel creation runbook [DONE]
* Add team that allows variable editing, release creation, and deployment

* Create development, test/production spaces.
* Add sample project to development.
* Use variable sets for database connection string.
  * Allow variables to be ignored. [DONE]
* Add promotion runbook.