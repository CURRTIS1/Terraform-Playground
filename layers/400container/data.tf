
data "terraform_remote_state" "state_000base" {
  backend = "s3"
  config = {
    bucket = "325618140111-bkoimepkjrfywagydigxfn"
    key    = "state_000base"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "state_100security" {
  backend = "s3"
  config = {
    bucket = "325618140111-bkoimepkjrfywagydigxfn"
    key    = "state_100security"
    region = "us-east-1"
  }
}
