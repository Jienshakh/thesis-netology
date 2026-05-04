#!/bin/bash

terraform -chdir=infra  output -raw inventory > inventory/inventory.ini