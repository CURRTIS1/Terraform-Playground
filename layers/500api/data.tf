
data "terraform_remote_state" "state_000base" {
  backend = "s3"
  config = {
    bucket = "286206761753-klwedolikzimdtoonagjfo"
    key    = "state_000base"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "state_100security" {
  backend = "s3"
  config = {
    bucket = "286206761753-klwedolikzimdtoonagjfo"
    key    = "state_100security"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "state_400container" {
  backend = "s3"
  config = {
    bucket = "286206761753-klwedolikzimdtoonagjfo"
    key    = "state_400container"
    region = "us-east-1"
  }
}
