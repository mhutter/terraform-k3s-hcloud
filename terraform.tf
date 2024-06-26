terraform {
  backend "s3" {
    bucket = "6dd34f27-5e26-4728-8b13-c4463c8c3bd5"
    key    = "k3s.tfstate"
    region = "eu-central-1" # dummy value
    # Credentials from ENV vars:
    # AWS_ACCESS_KEY_ID
    # AWS_SECRET_ACCESS_KEY
    # AWS_S3_ENDPOINT

    # cloudscale.ch compatibility
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}
