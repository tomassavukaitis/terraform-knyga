# stage/main.tf
module "webserver_cluster" {
  source = "./services/webserver-cluster"
  server_port = 80

}

terraform {
  backend "s3" {
    bucket  = "tomas-savukaitis"
    key     = "stage/services/webserver-cluster/terraform.tfstate"
    region  = "us-east-2"
     dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true    
  }
}