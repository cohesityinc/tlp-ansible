# TLS Lab

This playbook sets up internode encryption with:

* client certificate authentication
* hostname verification
* a certificate authority for signing C* node certs.

The playbook does *not* provision the cluster. It assumes that the cluster has
already been provisioned and that it is running in AWS.

The playbook has been tested with clusters created by [tlp-cluster](https://github.com/thelastpickle/tlp-ansible) that are running in AWS.

Other than the SSH key need to connect to the machines, the playbook does not require any additional AWS credentials.