terraform {
  backend "s3" {
    bucket                      = "tf-state-atata"
    # key                         = "state/terraform.tfstate"
    key    = "infra/terraform.tfstate"
    region                      = "us-east-1"

    endpoint                    = "https://storage.yandexcloud.net"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true

    force_path_style            = true
  }
}
