module "vpc-dev" {
  source                = "./modules/vpc"
  network_name          = "ex2-network"
  subnet_name           = "ex2-subnet"
  subnet_zone           = "ru-central1-a"
  subnet_cidr           = "10.0.1.0/24"
}

