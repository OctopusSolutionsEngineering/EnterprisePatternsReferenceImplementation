terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

resource "octopusdeploy_maven_feed" "sales_maven_feed" {
  download_attempts              = 3
  download_retry_backoff_seconds = 20
  feed_uri                       = "https://octopus-sales-public-maven-repo.s3.ap-southeast-2.amazonaws.com/snapshot"
  name                           = "Sales Maven Feed"
}