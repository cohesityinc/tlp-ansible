#!/bin/bash

set -e

TLS_LAB_DIR=/tmp/cassandra-tls-lab
CLIENT=blog.thelastpickle.com
TICKET=hostname_verification
PURPOSE="A cluster to demonstrate encryption related features"

PLAYBOOK_DIR=$(dirname "$BASH_SOURCE[0]")
INVENTORY_FILE=$PLAYBOOK_DIR/../../inventory/hosts.tlp_cluster

tlp_cluster() {
  $TLP_CLUSTER_HOME/bin/tlp-cluster "$@"
}

get_cassandra_public_ips() {
  cat $TLS_LAB_DIR/terraform.tfstate | jq -r '.modules[0].resources["aws_instance.cassandra.0","aws_instance.cassandra.1","aws_instance.cassandra.2"].primary.attributes.public_ip'
}

if [ -d "$PLAYBOOK_DIR/../../../tlp-cluster" ]; then
  TLP_CLUSTER_HOME=$PLAYBOOK_DIR/../../../tlp-cluster
else
  if [ "$#" -ne 1 ]; then
    echo "$PLAYBOOK_DIR/../../../tlp-cluster does not exist."
    echo "Please rerun setup.sh and specify the path to the tlp-cluster repo."
    echo
    echo "Usage: setup.sh <path-to-tlp_cluster-repo>"
    exit 1
  else
    TLP_CLUSTER_HOME=$1
  fi
fi

if [ ! -d $TLS_LAB_DIR ]; then
  echo "Creating $TLS_LAB_DIR"
  mkdir $TLS_LAB_DIR
fi

pushd $TLS_LAB_DIR
echo "Running tlp-cluster"
tlp_cluster init $CLIENT $TICKET "$PURPOSE"
tlp_cluster up -a
tlp_cluster use 3.11.4
tlp_cluster install
popd

echo "Creating Ansible inventory file at $INVENTORY_FILE"
cat > $INVENTORY_FILE <<EOF
[master]
localhost

[master:vars]
ansible_connection = local
# We want ansible to use python3
ansible_python_interpreter = `which python3`

[cassandra_nodes]
# This should include the public IPs of the C* node EC2 instances created by 
# tlp-cluster.
$(get_cassandra_public_ips)

[cassandra_nodes:vars]
ansible_python_interpreter = /usr/bin/python3
ansible_private_key_file = ~/.tlp-cluster/profiles/default/secret.pem
ansible_user = ubuntu
EOF
