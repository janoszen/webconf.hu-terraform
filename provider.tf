provider "exoscale" {
  key = var.exoscale_key
  secret = var.exoscale_secret
}

provider "aws" {
  region = var.exoscale_zone
  skip_metadata_api_check = true
  skip_credentials_validation = true
  skip_region_validation = true
  skip_get_ec2_platforms = true
  skip_requesting_account_id = true
  endpoints {
    s3 = "https://sos-${var.exoscale_zone}.exo.io"
    s3control = "https://sos-${var.exoscale_zone}.exo.io"
  }
  access_key = var.exoscale_key
  secret_key = var.exoscale_secret
}

provider "tls" {

}
