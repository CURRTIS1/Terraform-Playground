
data "terraform_remote_state" "state_000base" {
  backend = "s3"
  config = {
    bucket = "563940537117-gyzkxjkvvkxgmmenebvnuc"
    key    = "state_000base"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "state_100security" {
  backend = "s3"
  config = {
    bucket = "563940537117-gyzkxjkvvkxgmmenebvnuc"
    key    = "state_100security"
    region = "us-east-1"
  }
}
