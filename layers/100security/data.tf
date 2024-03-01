
data "terraform_remote_state" "state_000base" {
  backend = "s3"
  config = {
    bucket = "286206761753-klwedolikzimdtoonagjfo"
    key    = "state_000base"
    region = "us-east-1"
  }
}
