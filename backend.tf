terraform {
  backend "s3" {
    bucket = "webconf.hu-terraform"
    key    = "terraform"
    region = "at-vie-1"
    endpoint = "https://sos-at-vie-1.exo.io"
    skip_credentials_validation = true
    skip_get_ec2_platforms = true
    skip_metadata_api_check = true
    skip_region_validation = true
    skip_requesting_account_id = true
  }
}
