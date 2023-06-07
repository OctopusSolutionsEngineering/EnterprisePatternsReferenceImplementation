terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@localhost:15432/tenants_region?sslmode=disable"
  }
}

terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

variable "octopus_space_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The ID of the Octopus space to populate."
  default     = "Spaces-1"

  validation {
    condition     = length(var.octopus_space_id) > 7 && substr(var.octopus_space_id, 0, 7) == "Spaces-"
    error_message = "The space_id value must be a valid Space id, starting with \"Spaces-\"."
  }
}

provider "octopusdeploy" {
  address  = "http://localhost:18080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = var.octopus_space_id
}

variable "docker_username" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The DOcker username."
}

variable "docker_password" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Docker password"
}

variable "america_azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "america_azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "america_azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
  default     = "dummy"
}

variable "america_azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "america_k8s_cert" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The K8s user cert."
  default     = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURJVENDQWdtZ0F3SUJBZ0lJVEZqeGZIbndwUW93RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TXpBMU1EUXdPRE14TWpSYUZ3MHlOREExTURNd09ETXhNalZhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTJmaWE2MFZvME9MYWU3QUYKSGN3bjZIcit2aFpzZWt2MUQrb3RGdGFEelBIM085VTlRZFllN3hoVlVGelBuNGlBelYzeUliV1BEUER4a3N2VAo2OW1kNmovRW91WFRzSVVJNTFhdktVVk9pZ21KOTA4ZjB1REMwNlhuM2hOMWloT3BJdnZzOXZxcEZ4LzNDL3I1CjdkallsSDlQclZnTUthckxDNFU2SkMvOFhKOEZOSmE0WmhkWmZTMW85Q2VqQm9sZjZaSm9CRVBiM1lnek1oLzgKTUxQaDVRenNEdVRxMm85VGNHN3Z0SkducUVNUUVPUFpOaTZMNkFLOWNLRHNHL1B1N3U5V0xpdUU2SnpBdmNlawowck1WNHordjV1QmJVSXJ3OGJFL0V1NmhXSGJCWEVRNWgzSjRZOC9Gc0M1ZWd5eE9TNC8xNGE3LzFNTUYvLzZVCjlVNFdCd0lEQVFBQm8xWXdWREFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFmQmdOVkhTTUVHREFXZ0JUNzRVcmZmM0diRzlSbVZZUjEyQXliK21wNAovakFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBV1I5RTlaN3NuSmR4RHgxVFU1RHliREdlR244R2NRZVhYMVA3Cmxod1ZMOW5EVXhsTW9WdzhzODE3V0pZSDdQL2Q2Mldoamwya0QxTjNOb1UvU0E4T1RpNS9ZZk1tK2pDUFlYblkKdUpLUnBKKzlzd09WOENoSzk1OU1MVXZISmVKNXRrM0ZhRW4wUUU1RUU5TjhObGhabzNpQ3I0dmloU2xXZEFCOApaTTlMaWFxbUNpMWNzeXc0ZCtwTEJBU0YxR2dZRHdkUkdqaXBrYUtWcGRYSDBnK0t1TTlqOEFuRUVGRFNRTDcxClJrQklnSXBRWmhweFU3RzdiYjBhQkUxS2JLU0s0SUJkMS95aUEwUzNsd3ROL1JVRFh6TmxKVTFHSmhRbHRmYVIKK1hCcHo0U2JRUFczSEJpYlZKdDkzL3VscWViaW5ramZHQ1M1WjFtbG9HY1JEanZrdGc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCi0tLS0tQkVHSU4gUlNBIFBSSVZBVEUgS0VZLS0tLS0KTUlJRW93SUJBQUtDQVFFQTJmaWE2MFZvME9MYWU3QUZIY3duNkhyK3ZoWnNla3YxRCtvdEZ0YUR6UEgzTzlVOQpRZFllN3hoVlVGelBuNGlBelYzeUliV1BEUER4a3N2VDY5bWQ2ai9Fb3VYVHNJVUk1MWF2S1VWT2lnbUo5MDhmCjB1REMwNlhuM2hOMWloT3BJdnZzOXZxcEZ4LzNDL3I1N2RqWWxIOVByVmdNS2FyTEM0VTZKQy84WEo4Rk5KYTQKWmhkWmZTMW85Q2VqQm9sZjZaSm9CRVBiM1lnek1oLzhNTFBoNVF6c0R1VHEybzlUY0c3dnRKR25xRU1RRU9QWgpOaTZMNkFLOWNLRHNHL1B1N3U5V0xpdUU2SnpBdmNlazByTVY0eit2NXVCYlVJcnc4YkUvRXU2aFdIYkJYRVE1CmgzSjRZOC9Gc0M1ZWd5eE9TNC8xNGE3LzFNTUYvLzZVOVU0V0J3SURBUUFCQW9JQkFRRFh4YzQyRUtQT0JJT2IKNVlkckUrcDlyU1A0TUdKNlBpNzk3aWRzY0RaUTcwWjdLSUJYYUF0L1RHdEgvbGhaNk5yNGNZTjc4eXNFK0k5cgpiZkwvaXBGVWpvT3RiaTI4bERWWUxPdUF3MmNZSnBFNURFN0loazdYRFdrVzRkUjlOekU3dkgrN2ppOU5BUXVpCkJIVGRDc2g3Vi93YjhRazVSaVZ4NWhURU5leHdFZmM3N0QyL2xXZlVQdElCNDBOUlFsZEkyUUgyT1dzdjdBNUIKTVYxMUx5NDRtMG5MNkh3VFUyQWNXZTlIV21YTlZTZlJFcW9LYnBMZVczMHYxZXpKMWhUSHlIYWE5em5mTUdKZgpjU1AramcvTURvMW1MRWFsN0hXT2hVVy95UmdvSFd6OVdFK2NBUVJHUjVrR2FCR3BmNkl3SmJYMkdoZ28wTGtmCndyQitiZzJCQW9HQkFQUHdlVEtJaEZwOGtmcGVpQjJhaW15TnFwRkJISGRHQmM3MFFwOFEzU1ZXRmpLS09qa1gKWFp6UHJwOFh6QWN0elNlRmZBeE5zcG92TXdBRklDZWViWEFVa3V5MzlEdnM0WU1xZ2tzNkVPMGE1Q3lGN0Q4WgpFUXQ0cHAxbGhyZktxSW9WTmNmT1RTTHFTejFQSmc0MC9oRzQyUHZmRjB6dk1sd08vL1RPWXFreEFvR0JBT1MvCmRBYzNPdnl3LzRwc3NMaVBVRmlwNUp1ZmMvaWJ4aVM4NVQ3TEY1eG9TWUNHaVR1Q2c0SVJoUUFQMEl0NGtoUUYKUTN3ck8yb09IVTNZaHJzOTY2VUMzNTFVZ280enhYWmQzQ0xuOEpDUjBJdWxpMFVhc0pMMVZEc29DVGwrc2F5Vwp1b3g1eldaK0dIWjAwanpTWWNYQW1WK1VwQ3pNOEVxS2pyZGhzR1MzQW9HQVIxTDJmTm9CcU50bmEwY2NrVnRRClFmRWlBQnFEa2pROUdvZTh1dm1aVDROZU5pVElaVXo1cUJIcFFzY1lkcmpqbFR5b1NvaWxRZ091NjhDVDZFR2cKU2ZjYUJuQzZ6cEt5VlVHbW13dzlTclprSk1oN2pPOXRWbWRPZ0JMaFV2ZkVVNnRqOENuWHorK2xWQ1hDUU1FcAowRkMxME44bjF1elJVcTFvRlZJSzh1RUNnWUFJSjByYmR2eURSVXZXZzBsSlN0SnlWcHZ2Y0IrU0hQdFRFK2lYCjlHVkREZlNRd0Rya0JDTHIzL1A5ckpLaVpnbk83T0VhNisrU09DNlROOFNWcC85ZVFsdjJINjBIcEpERlIxTXgKYTFNSDFDcTZ6NHZIU3N4QWNMNHYzWjEyankyR0dWbE02SXFKdkxUaWhBZDZZNFZZcHlUUVkxdjJ2TmRUME55RgpiTlg4d1FLQmdEVHJ0NERuQ1VVU0xRS3I3d3B5QVNkejIxam1PU3lNK1dTc2NQVVFxY2FZWWpWZTNnU1RidUV0CmYwODc2R1QxNEJNelg2NklFaEJvWVNrcGFQWUxvWmN3dGlnNThLb0UwKzJoREtxdDRLa2hZbWtBTkZ4TyttVDgKQW5mYmhOZDB1enJscEdPdnhmRkNiMEQ5cjlMaEhJaHVjSWpwWXYvNWc5a3NPaXVEbndSdQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo="
}

variable "america_k8s_url" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The K8s URL."
  default     = "http://example.org"
}

variable "america_docker_username" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Docker username."
  default     = ""
}

variable "america_docker_password" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Docker password"
  default     = ""
}


variable "europe_azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "europe_azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "europe_azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
  default     = "dummy"
}

variable "europe_azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "europe_k8s_cert" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The K8s user cert."
  default     = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURJVENDQWdtZ0F3SUJBZ0lJVEZqeGZIbndwUW93RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TXpBMU1EUXdPRE14TWpSYUZ3MHlOREExTURNd09ETXhNalZhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTJmaWE2MFZvME9MYWU3QUYKSGN3bjZIcit2aFpzZWt2MUQrb3RGdGFEelBIM085VTlRZFllN3hoVlVGelBuNGlBelYzeUliV1BEUER4a3N2VAo2OW1kNmovRW91WFRzSVVJNTFhdktVVk9pZ21KOTA4ZjB1REMwNlhuM2hOMWloT3BJdnZzOXZxcEZ4LzNDL3I1CjdkallsSDlQclZnTUthckxDNFU2SkMvOFhKOEZOSmE0WmhkWmZTMW85Q2VqQm9sZjZaSm9CRVBiM1lnek1oLzgKTUxQaDVRenNEdVRxMm85VGNHN3Z0SkducUVNUUVPUFpOaTZMNkFLOWNLRHNHL1B1N3U5V0xpdUU2SnpBdmNlawowck1WNHordjV1QmJVSXJ3OGJFL0V1NmhXSGJCWEVRNWgzSjRZOC9Gc0M1ZWd5eE9TNC8xNGE3LzFNTUYvLzZVCjlVNFdCd0lEQVFBQm8xWXdWREFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFmQmdOVkhTTUVHREFXZ0JUNzRVcmZmM0diRzlSbVZZUjEyQXliK21wNAovakFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBV1I5RTlaN3NuSmR4RHgxVFU1RHliREdlR244R2NRZVhYMVA3Cmxod1ZMOW5EVXhsTW9WdzhzODE3V0pZSDdQL2Q2Mldoamwya0QxTjNOb1UvU0E4T1RpNS9ZZk1tK2pDUFlYblkKdUpLUnBKKzlzd09WOENoSzk1OU1MVXZISmVKNXRrM0ZhRW4wUUU1RUU5TjhObGhabzNpQ3I0dmloU2xXZEFCOApaTTlMaWFxbUNpMWNzeXc0ZCtwTEJBU0YxR2dZRHdkUkdqaXBrYUtWcGRYSDBnK0t1TTlqOEFuRUVGRFNRTDcxClJrQklnSXBRWmhweFU3RzdiYjBhQkUxS2JLU0s0SUJkMS95aUEwUzNsd3ROL1JVRFh6TmxKVTFHSmhRbHRmYVIKK1hCcHo0U2JRUFczSEJpYlZKdDkzL3VscWViaW5ramZHQ1M1WjFtbG9HY1JEanZrdGc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCi0tLS0tQkVHSU4gUlNBIFBSSVZBVEUgS0VZLS0tLS0KTUlJRW93SUJBQUtDQVFFQTJmaWE2MFZvME9MYWU3QUZIY3duNkhyK3ZoWnNla3YxRCtvdEZ0YUR6UEgzTzlVOQpRZFllN3hoVlVGelBuNGlBelYzeUliV1BEUER4a3N2VDY5bWQ2ai9Fb3VYVHNJVUk1MWF2S1VWT2lnbUo5MDhmCjB1REMwNlhuM2hOMWloT3BJdnZzOXZxcEZ4LzNDL3I1N2RqWWxIOVByVmdNS2FyTEM0VTZKQy84WEo4Rk5KYTQKWmhkWmZTMW85Q2VqQm9sZjZaSm9CRVBiM1lnek1oLzhNTFBoNVF6c0R1VHEybzlUY0c3dnRKR25xRU1RRU9QWgpOaTZMNkFLOWNLRHNHL1B1N3U5V0xpdUU2SnpBdmNlazByTVY0eit2NXVCYlVJcnc4YkUvRXU2aFdIYkJYRVE1CmgzSjRZOC9Gc0M1ZWd5eE9TNC8xNGE3LzFNTUYvLzZVOVU0V0J3SURBUUFCQW9JQkFRRFh4YzQyRUtQT0JJT2IKNVlkckUrcDlyU1A0TUdKNlBpNzk3aWRzY0RaUTcwWjdLSUJYYUF0L1RHdEgvbGhaNk5yNGNZTjc4eXNFK0k5cgpiZkwvaXBGVWpvT3RiaTI4bERWWUxPdUF3MmNZSnBFNURFN0loazdYRFdrVzRkUjlOekU3dkgrN2ppOU5BUXVpCkJIVGRDc2g3Vi93YjhRazVSaVZ4NWhURU5leHdFZmM3N0QyL2xXZlVQdElCNDBOUlFsZEkyUUgyT1dzdjdBNUIKTVYxMUx5NDRtMG5MNkh3VFUyQWNXZTlIV21YTlZTZlJFcW9LYnBMZVczMHYxZXpKMWhUSHlIYWE5em5mTUdKZgpjU1AramcvTURvMW1MRWFsN0hXT2hVVy95UmdvSFd6OVdFK2NBUVJHUjVrR2FCR3BmNkl3SmJYMkdoZ28wTGtmCndyQitiZzJCQW9HQkFQUHdlVEtJaEZwOGtmcGVpQjJhaW15TnFwRkJISGRHQmM3MFFwOFEzU1ZXRmpLS09qa1gKWFp6UHJwOFh6QWN0elNlRmZBeE5zcG92TXdBRklDZWViWEFVa3V5MzlEdnM0WU1xZ2tzNkVPMGE1Q3lGN0Q4WgpFUXQ0cHAxbGhyZktxSW9WTmNmT1RTTHFTejFQSmc0MC9oRzQyUHZmRjB6dk1sd08vL1RPWXFreEFvR0JBT1MvCmRBYzNPdnl3LzRwc3NMaVBVRmlwNUp1ZmMvaWJ4aVM4NVQ3TEY1eG9TWUNHaVR1Q2c0SVJoUUFQMEl0NGtoUUYKUTN3ck8yb09IVTNZaHJzOTY2VUMzNTFVZ280enhYWmQzQ0xuOEpDUjBJdWxpMFVhc0pMMVZEc29DVGwrc2F5Vwp1b3g1eldaK0dIWjAwanpTWWNYQW1WK1VwQ3pNOEVxS2pyZGhzR1MzQW9HQVIxTDJmTm9CcU50bmEwY2NrVnRRClFmRWlBQnFEa2pROUdvZTh1dm1aVDROZU5pVElaVXo1cUJIcFFzY1lkcmpqbFR5b1NvaWxRZ091NjhDVDZFR2cKU2ZjYUJuQzZ6cEt5VlVHbW13dzlTclprSk1oN2pPOXRWbWRPZ0JMaFV2ZkVVNnRqOENuWHorK2xWQ1hDUU1FcAowRkMxME44bjF1elJVcTFvRlZJSzh1RUNnWUFJSjByYmR2eURSVXZXZzBsSlN0SnlWcHZ2Y0IrU0hQdFRFK2lYCjlHVkREZlNRd0Rya0JDTHIzL1A5ckpLaVpnbk83T0VhNisrU09DNlROOFNWcC85ZVFsdjJINjBIcEpERlIxTXgKYTFNSDFDcTZ6NHZIU3N4QWNMNHYzWjEyankyR0dWbE02SXFKdkxUaWhBZDZZNFZZcHlUUVkxdjJ2TmRUME55RgpiTlg4d1FLQmdEVHJ0NERuQ1VVU0xRS3I3d3B5QVNkejIxam1PU3lNK1dTc2NQVVFxY2FZWWpWZTNnU1RidUV0CmYwODc2R1QxNEJNelg2NklFaEJvWVNrcGFQWUxvWmN3dGlnNThLb0UwKzJoREtxdDRLa2hZbWtBTkZ4TyttVDgKQW5mYmhOZDB1enJscEdPdnhmRkNiMEQ5cjlMaEhJaHVjSWpwWXYvNWc5a3NPaXVEbndSdQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo="
}

variable "europe_k8s_url" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The K8s URL."
  default     = "http://example.org"
}

variable "europe_docker_username" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Docker username."
  default     = ""
}

variable "europe_docker_password" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Docker password"
  default     = ""
}

variable "slack_bot_token" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Slack Bot Token"
  default     = "dummy"
}

variable "slack_support_users" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Slack support users"
  default     = "dummy"
}

variable "azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
  default     = "dummy"
}

variable "azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "generic_tenant_count" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "How many generic tenants to create."
  default     = "0"
}

module "octopus" {
  source                        = "../octopus"
  america_azure_application_id  = var.america_azure_application_id
  america_azure_subscription_id = var.america_azure_subscription_id
  america_azure_password        = var.america_azure_password
  america_azure_tenant_id       = var.america_azure_tenant_id
  america_k8s_cert              = var.america_k8s_cert
  america_k8s_url               = var.america_k8s_url
  europe_azure_application_id   = var.europe_azure_application_id
  europe_azure_subscription_id  = var.europe_azure_subscription_id
  europe_azure_password         = var.europe_azure_password
  europe_azure_tenant_id        = var.europe_azure_tenant_id
  europe_k8s_cert               = var.europe_k8s_cert
  europe_k8s_url                = var.europe_k8s_url
  america_docker_username       = var.america_docker_username
  america_docker_password       = var.america_docker_password
  europe_docker_username        = var.europe_docker_username
  europe_docker_password        = var.europe_docker_password
  slack_bot_token               = var.slack_bot_token
  slack_support_users           = var.slack_support_users
  docker_username               = var.docker_username
  docker_password               = var.docker_password
  azure_application_id          = var.azure_application_id
  azure_subscription_id         = var.azure_subscription_id
  azure_password                = var.azure_password
  azure_tenant_id               = var.azure_tenant_id
  generic_tenant_count          = var.generic_tenant_count
}