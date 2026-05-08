#!/bin/bash

terraform -chdir=init output -json | jq -r 'to_entries[] | "\(.key)=\(.value.value)"' > .secrets

jq -r '"sa_json_key=\(.)"' .authorized_key.json >> .secrets

jq -r '"csi_sa_json_key=\(.)"' ./k8s/CSI/.authorized_key.json >> .secrets

ssh_public_key=$(terraform -chdir=infra output -raw ssh_public_key) 
username=$(terraform -chdir=infra output -raw username) 

cat >> ./.secrets <<EOF
ssh_public_key="$ssh_public_key"
username="$username"
EOF

