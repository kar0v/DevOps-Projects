terraform {
  backend "s3" {
    bucket = "tfstate-delete-me-manually-kkarov"
    key    = "feedback_logger/terraform.tfstate"
    region = "eu-central-1"
  }
}
