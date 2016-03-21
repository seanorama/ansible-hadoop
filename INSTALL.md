ansible-hadoop installation guide
---------

* These Ansible playbooks can build a Rackspace Cloud environment and install HDP on it. Follow this [link](#install-hdp-on-rackspace-cloud).

* These Ansible playbooks can build an Amazon AWS environment and install HDP on it. Follow this [link](#install-hdp-on-amazon-aws).

* It can also install HDP on existing Linux devices, be it dedicated devices in a datacenter or VMs running on a hypervizor. Follow this [link](#install-hdp-on-existing-devices).


---


# Install HDP on Rackspace Cloud

## Build setup

First step is to setup the build node / workstation.

This build node or workstation will run the Ansible code and build the Hadoop cluster (itself can be a Hadoop node).

This node needs to be able to contact the cluster devices via SSH and the Rackspace APIs via HTTPS.

The following steps must be followed to install Ansible and the prerequisites on this build node / workstation, depending on its operating system:

### CentOS/RHEL 6

1. Install required packaged:

  ```
  sudo su -
  yum -y remove python-crypto
  yum install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
  yum repolist; yum install gcc gcc-c++ python-virtualenv python-pip python-devel sshpass git vim-enhanced -y
  ```

2. Create the Python virtualenv and install Ansible:

  ```
  virtualenv ansible2; source ansible2/bin/activate
  pip install oslo.config==3.0.0 keyring==5.7.1 importlib ansible pyrax
  ```

3. Generate SSH public/private key pair (press Enter for defaults):

  ```
  ssh-keygen -q -t rsa
  ```

### CentOS/RHEL 7

1. Install required packaged:

  ```
  sudo su -
  yum install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
  yum repolist; yum install gcc gcc-c++ python-virtualenv python-pip python-devel sshpass git vim-enhanced -y
  ```

2. Create the Python virtualenv and install Ansible:

  ```
  virtualenv ansible2; source ansible2/bin/activate
  pip install ansible pyrax
  ```

3. Generate SSH public/private key pair (press Enter for defaults):

  ```
  ssh-keygen -q -t rsa
  ```

### Ubuntu 14+ / Debian 8

1. Install required packaged:

  ```
  sudo su -
  apt-get update; apt-get -y install python-virtualenv python-pip python-dev sshpass git vim
  ```

2. Create the Python virtualenv and install Ansible:

  ```
  virtualenv ansible2; source ansible2/bin/activate
  pip install ansible pyrax
  ```

3. Generate SSH public/private key pair (press Enter for defaults):

  ```
  ssh-keygen -q -t rsa
  ```


## Setup the Rackspace credentials file

The cloud environment requires the standard [pyrax](https://github.com/rackspace/pyrax/blob/master/docs/getting_started.md#authenticating) credentials file that looks like this:
```
[rackspace_cloud]
username = my_username
api_key = 01234567890abcdef
```

Replace `my_username` with your Rackspace Cloud username and `01234567890abcdef` with your API key.

Save this file as `.raxpub` under the home folder of the user running the playbook.


## Clone the repository

On the same build node / workstation, run the following:

```
cd; git clone https://github.com/rackerlabs/ansible-hadoop
```


## Set master-nodes variables

There are three types of nodes:

1. `master-nodes` are nodes running the master Hadoop services. You can specify one, two or three nodes.
 
 With two or three master nodes the HDFS NameNode will be configured in HA mode.

1. `slave-nodes` are nodes running the slave Hadoop services and store HDFS data. You can specify 0 or more nodes.
 
 By specifying no slave-nodes, the scripts will deploy a single-node HDP, similar with the Hortonworks sandbox.

1. `edge-nodes` are client only nodes and have only the client libraries installed. These are optional. 



Modify the file at `~/ansible-hadoop/playbooks/group_vars/master-nodes` to set master-nodes specific information (you can remove all the existing content from this file).

| Variable           | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| cluster_interface  | Should be set to the network device that the HDP nodes will use to communicate between them. |
| cloud_nodes_count  | Should be set to the desired number of master-nodes (1, 2 or 3).   |
| cloud_image        | The OS image to be used. Can be `CentOS 6 (PVHVM)`, `CentOS 7 (PVHVM)` or `Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)`. |
| cloud_flavor       | [Size flavor](https://developer.rackspace.com/docs/cloud-servers/v2/developer-guide/#list-flavors-with-nova) of the nodes. Minimum `general1-8` for Hadoop nodes. |
| hadoop_disk        | The disk that will be mounted under `/hadoop`. If the [size flavor](https://developer.rackspace.com/docs/cloud-servers/v2/developer-guide/#list-flavors-with-nova) provides with an ephemeral disk, set this to `xvde`. Remove this variable if `/hadoop` should just be a folder on the root filesystem or if the disk has already been partitioned and mounted. |
| datanode_disks     | Only used for single-nodes clusters. The disks that will be mounted under `/grid/{0..n}`. Should be set if one or more separate disk devices are used for storing HDFS data. |

For single-node clusters, if Rackspace Cloud Block Storage is to be built for storing HDFS data, set the following options:

| Variable           | Description                                                                         |
| ------------------ | ----------------------------------------------------------------------------------- |
| build_datanode_cbs | Set to `true` to build CBS for . `datanode_disks` also needs to be set (for example, to build two CBS disks, set `datanode_disks` to `['xvde', 'xvdf']`). |
| cbs_disks_size     | The size of the disk(s) in GB.                                                      |
| cbs_disks_type     | The type of the disk(s), can be `SATA` or `SSD`.                                    |

- Example with using 2 x `general1-8` master nodes running CentOS 7 with ServiceNet(`eth1`) as the cluster interface:

  ```
  cluster_interface: 'eth1'
  cloud_nodes_count: 2
  cloud_image: 'CentOS 7 (PVHVM)'
  cloud_flavor: 'general1-8'
  ```

- Example with using 2 x `onmetal-general2-small` master nodes running Ubuntu 14:

  ```
  cloud_nodes_count: 2
  cloud_image: 'OnMetal - Ubuntu 14.04 LTS (Trusty Tahr)'
  cloud_flavor: 'onmetal-general2-small'
  ```

- Example for installing a single-node cluster (Hortonworks sandbox in Rackspace Cloud) and using the ephemeral disk of the `performance2-15` flavor for the `/hadoop` mount (for a single node cluster, make sure `cloud_nodes_count` is set to `0` in `group_vars/slave-nodes`):

  ```
  cluster_interface: 'eth1'
  cloud_nodes_count: 1
  cloud_image: 'CentOS 7 (PVHVM)'
  cloud_flavor: 'performance2-15'
  hadoop_disk: xvde
  ```

- Example for installing a single-node OnMetal cluster (Hortonworks sandbox on OnMetal) and using the ephemeral SSD disks of the `onmetal-io2` flavor for both the `/hadoop` mount and HDFS data (for a single node cluster, make sure `cloud_nodes_count` is set to `0` in `group_vars/slave-nodes`):

  ```
  cloud_nodes_count: 1
  cloud_image: 'OnMetal - CentOS 7'
  cloud_flavor: 'onmetal-io2'
  hadoop_disk: sdc
  datanode_disks: ['sdd']
  ```

## Set slave-nodes variables

Modify the file at `~/ansible-hadoop/playbooks/group_vars/slave-nodes` to set slave-nodes specific information (you can remove all the existing content from this file).

| Variable           | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| cluster_interface  | Should be set to the network device that the HDP nodes will use to communicate between them. |
| cloud_nodes_count  | Should be set to the desired number of slave-nodes (0 or more).    |
| cloud_image        | The OS image to be used. Can be `CentOS 6 (PVHVM)`, `CentOS 7 (PVHVM)` or `Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)`. |
| cloud_flavor       | [Size flavor](https://developer.rackspace.com/docs/cloud-servers/v2/developer-guide/#list-flavors-with-nova) of the nodes. Minimum `general1-8` for Hadoop nodes. |
| datanode_disks     | The disks that will be mounted under `/grid/{0..n}`. Should be set if one or more separate disk devices are used for storing HDFS data and remove it if the data should be stored on the root filesystem. Can be set to `['xvde']` or `['xvde', 'xvdf']` if the [size flavor](https://developer.rackspace.com/docs/cloud-servers/v2/developer-guide/#list-flavors-with-nova) provides with an ephemeral disk. Alternatively, you can let the playbook build Cloud Block Storage for this purpose. |

If Rackspace Cloud Block Storage is to be built for storing HDFS data, set the following options:

| Variable           | Description                                                                         |
| ------------------ | ----------------------------------------------------------------------------------- |
| build_datanode_cbs | Set to `true` to build CBS. `datanode_disks` also needs to be set (for example, to build two CBS disks, set `datanode_disks` to `['xvde', 'xvdf']`). |
| cbs_disks_size     | The size of the disk(s) in GB.                                                      |
| cbs_disks_type     | The type of the disk(s), can be `SATA` or `SSD`.                                    |

- Example with 3 x `general1-8` nodes running CentOS 7 and 2 x 200GB CBS disks on each node:

  ```
  cluster_interface: 'eth1'
  cloud_nodes_count: 3
  cloud_image: 'CentOS 7 (PVHVM)'
  cloud_flavor: 'general1-8'
  build_datanode_cbs: true
  cbs_disks_size: 200
  cbs_disks_type: 'SATA'
  datanode_disks: ['xvde', 'xvdf']
  ```

- Example with 3 x OnMetal I/O v2 nodes running CentOS 7 and using the ephemeral SSD disks of the `onmetal-io2` flavor as the HDFS data drives:

  ```
  cloud_nodes_count: 3
  cloud_image: 'OnMetal - CentOS 7'
  cloud_flavor: 'onmetal-io2'
  datanode_disks: ['sdc', 'sdd']
  ```


## Set edge-nodes variables

Optionally, if edge nodes are used, modify the file at `~/ansible-hadoop/playbooks/group_vars/edge-nodes` to set edge-nodes specific information (you can remove all the existing content from this file).

The same guidelines as for the master nodes above can be used here.


## Set the global variables

Modify the file at `~/ansible-hadoop/playbooks/group_vars/all` to set the cluster configuration.

The following table will describe the most important variables:

| Variable             | Description                                                         |
| -------------------- | ------------------------------------------------------------------- |
| cluster_name         | The name of the HDP cluster                                         |
| hdp_version          | The HDP major version that should be installed                      |
| admin_password       | This is the Ambari admin user password                              |
| services_password    | This is a password used by everything else (like hive's database)   |
| install_*            | Set these to true in order to install the respective HDP component  |
| rax_credentials_file | The location of the Rackspace credentials file as set above         |
| rax_region           | The Rackspace region where the Cloud Servers should be built        |
| allowed_external_ips | A list of IPs allowed to connect to cluster nodes                   |
| ssh keyfile          | The SSH keyfile that will be placed on cluster nodes at build time. |
| ssh keyname          | The name of the SSH key. Make sure you change this if another key was previously used with the same name. |


## Provision the Cloud environment
The first step is to run the script that will provision the Cloud environment:

```
cd ~/ansible-hadoop/ && bash provision_rax.sh
```


## Bootstrapping

Then run the bootstrapping script that will setup the prerequisites on the cluster nodes.

```
cd ~/ansible-hadoop/ && bash bootstrap_rax.sh
```


## HDP Installation

Then run the script that will install Ambari and build the cluster using Ambari Blueprints:

```
cd ~/ansible-hadoop/ && bash hortonworks_rax.sh
```


## Login to Ambari

Once you are at this point you can see progress by accessing the Ambari interface.

The Ambari server runs on the last master-node and be accessed on port 8080.


---


# Install HDP on Amazon AWS

## Build setup

First step is to setup the build node / workstation.

This build node or workstation will run the Ansible code and build the Hadoop cluster (itself can be a Hadoop node).

This node needs to be able to contact the cluster devices via SSH and the Amazon APIs via HTTPS.

The following steps must be followed to install Ansible and the prerequisites on this build node / workstation, depending on its operating system:

### CentOS/RHEL 6

1. Install Ansible and git:

  ```
  sudo su -
  yum -y remove python-crypto
  yum install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
  yum repolist; yum install gcc gcc-c++ python-pip python-devel sshpass git vim-enhanced -y
  pip install ansible boto
  ```

2. Generate SSH public/private key pair (press Enter for defaults):

  ```
  ssh-keygen -q -t rsa
  ```

### CentOS/RHEL 7

1. Install Ansible and git:

  ```
  sudo su -
  yum install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
  yum repolist; yum install gcc gcc-c++ python-pip python-devel sshpass git vim-enhanced -y
  pip install ansible boto
  ```

2. Generate SSH public/private key pair (press Enter for defaults):

  ```
  ssh-keygen -q -t rsa
  ```

### Ubuntu 14+ / Debian 8

1. Install Ansible and git:

  ```
  sudo su -
  apt-get update; apt-get -y install python-pip python-dev sshpass git vim
  pip install ansible boto
  ```

2. Generate SSH public/private key pair (press Enter for defaults):

  ```
  ssh-keygen -q -t rsa
  ```

## Setup the Amazon AWS credentials file

The Amazon AWS environment requires the standard [boto](https://github.com/boto/boto#getting-started-with-boto) credentials file that looks like this:
```
[default]
aws_access_key_id = YOUR_KEY
aws_secret_access_key = YOUR_SECRET
```

Replace the `YOUR_KEY` and `YOUR_SECRET` with the correct credential values.
You can generate these credentials in your [Amazon AWS Console](https://console.aws.amazon.com).

Save this file as `.aws/credentials` under the home folder of the user running the playbook. You may need to create the `.aws` folder as well.


## Clone the repository

On the same build node / workstation, run the following:

```
cd; git clone https://github.com/rackerlabs/ansible-hadoop
```


## Set master-nodes variables

There are three types of nodes:

1. `master-nodes` are nodes running the master Hadoop services. You can specify one, two or three nodes.
 
 With two or three master nodes the HDFS NameNode will be configured in HA mode.

1. `slave-nodes` are nodes running the slave Hadoop services and store HDFS data. You can specify 0 or more nodes.
 
 By specifying no slave-nodes, the scripts will deploy a single-node HDP, similar with the Hortonworks sandbox.

1. `edge-nodes` are client only nodes and have only the client libraries installed. These are optional. 



Modify the file at `~/ansible-hadoop/playbooks/group_vars/master-nodes` to set master-nodes specific information (you can remove all the existing content from this file).

| Variable           | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| cluster_interface  | Should be set to the network device that the HDP nodes will use to communicate between them, Default is `eth0`, as all nodes are under VPC. |
| aws_nodes_count  | Should be set to the desired number of master-nodes (1, 2 or 3).   |
| aws_image        | The AMI OS image to be used. This is confirmed working with RHEL7 Image for now, but others `should` work as well. You can find the AMI IDs in [Amazon AWS Console EC2 Section](https://console.aws.amazon.com).. |
| aws_instance_type       | [Instance type](https://aws.amazon.com/ec2/instance-types/) of the nodes. Minimum `t2.large` for Hadoop nodes. |
| ebs_disks_devices | Should be set if a separate disk device is used for `/hadoop`, usually `xvda`. Set to `[]` if `/hadoop` should just be a folder on the root filesystem or if the disk has already been partitioned and mounted. |

If Elastic Block Storage is to be built for storing /hadoop data, set the following options:

| Variable           | Description                                                                         |
| ------------------ | ----------------------------------------------------------------------------------- |
| build_ebs          | Set to `true` to build EBS. |
| ebs_disks_size     | The size of the disk(s) in GB.                                                      |
| ebs_disks_type     | The type of the disk(s), can be `standard` or `ssd`.                                    |

- Example for using the `eth0` interface, no Elastic Block Storage device and 2 x `t2.large` nodes running RHEL7:

  ```
  cluster_interface: 'eth0'
  aws_nodes_count: 2
  aws_image: 'ami-2051294a'
  aws_instance_type: 't2.large'
  build_ebs: false
  ebs_disks_devices: []
  ```


## Set slave-nodes variables

Modify the file at `~/ansible-hadoop/playbooks/group_vars/slave-nodes` to set slave-nodes specific information (you can remove all the existing content from this file).

| Variable           | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| cluster_interface  | Should be set to the network device that the HDP nodes will use to communicate between them, Default is `eth0`, as all nodes are under VPC. |
| aws_nodes_count  | Should be set to the desired number of master-nodes (1, 2 or 3).   |
| aws_image        | The AMI OS image to be used. This is confirmed working with RHEL7 Image for now, but others `should` work as well. You can find the AMI IDs in [Amazon AWS Console EC2 Section](https://console.aws.amazon.com).. |
| aws_instance_type       | [Instance type](https://aws.amazon.com/ec2/instance-types/) of the nodes. Minimum `t2.large` for Hadoop nodes. |
| ebs_disks_devices | Should be set if a separate disk device is used for `/hadoop`, usually `xvda`. Set to `[]` if `/hadoop` should just be a folder on the root filesystem or if the disk has already been partitioned and mounted. |

If Elastic Block Storage is to be built for storing /hadoop data, set the following options:

| Variable           | Description                                                                         |
| ------------------ | ----------------------------------------------------------------------------------- |
| build_ebs          | Set to `true` to build EBS. |
| ebs_disks_size     | The size of the disk(s) in GB.                                                      |
| ebs_disks_type     | The type of the disk(s), can be `standard` or `ssd`.                                    |

- Example for using the `eth0` interface, 2x 100GB Elastic Block Storage device and 2 x `t2.large` nodes running RHEL7:

  ```
  cluster_interface: 'eth0'
  aws_nodes_count: 2
  aws_image: 'ami-2051294a'
  aws_instance_type: 't2.large'
  build_ebs: false
  ebs_disks_size: 100
  ebs_disks_type: 'standard'
  ebs_disks_devices: ['xvde', 'xvdf']
  ```


## Set edge-nodes variables

Optionally, if edge nodes are used, modify the file at `~/ansible-hadoop/playbooks/group_vars/edge-nodes` to set edge-nodes specific information (you can remove all the existing content from this file).

The same guidelines as for the master nodes above can be used here.


## Set the global variables

Modify the file at `~/ansible-hadoop/playbooks/group_vars/all` to set the cluster configuration.

The following table will describe the most important variables:

| Variable             | Description                                                         |
| -------------------- | ------------------------------------------------------------------- |
| cluster_name         | The name of the HDP cluster                                         |
| hdp_version          | The HDP major version that should be installed                      |
| admin_password       | This is the Ambari admin user password                              |
| services_password    | This is a password used by everything else (like hive's database)   |
| install_*            | Set these to true in order to install the respective HDP component  |
| rax_region           | The Rackspace region where the Cloud Servers should be built        |
| allowed_external_ips | A list of IPs allowed to connect to cluster nodes                   |
| ssh keyfile          | The SSH keyfile that will be placed on cluster nodes at build time. |
| ssh keyname          | The name of the SSH key. Make sure you change this if another key was previously used with the same name. |
| aws_credentials_file | The location of the AWS credentials file as set above               |
| aws_region           | The Amazon AWS region where the Cloud Servers should be built       |                 
| aws_vpc_cidr_block   | The CIDR block to be used in VPC and Subnet for the Cluster         |

## Provision the Cloud environment
The first step is to run the script that will provision the Cloud environment:

```
cd ~/ansible-hadoop/ && bash provision_aws.sh
```


## Bootstrapping

Then run the bootstrapping script that will setup the prerequisites on the cluster nodes.

```
cd ~/ansible-hadoop/ && bash bootstrap_aws.sh
```


## HDP Installation

Then run the script that will install Ambari and build the cluster using Ambari Blueprints:

```
cd ~/ansible-hadoop/ && bash hortonworks_aws.sh
```


## Login to Ambari

Once you are at this point you can see progress by accessing the Ambari interface.

The Ambari server runs on the last master-node and be accessed on port 8080.


---


# Install HDP on existing devices


## Build setup

First step is to setup the build node / workstation.

This build node or workstation will run the Ansible code and build the Hadoop cluster (itself can be a Hadoop node).

This node needs to be able to contact the cluster devices via SSH.

All the SSH logins must be known / prepared in advance or alternative SSH public-key authentication can also be used.

The following steps must be followed to install Ansible and the prerequisites on this build node / workstation, depending on its operating system:

### CentOS/RHEL 6

1. Install required packaged:

  ```
  sudo su -
  yum install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
  yum repolist; yum install python-virtualenv python-pip python-devel sshpass git vim-enhanced -y
  ```

2. Create the Python virtualenv and install Ansible:

  ```
  virtualenv ansible2; source ansible2/bin/activate
  pip install ansible pyrax
  ```

### CentOS/RHEL 7

1. Install required packaged:

  ```
  sudo su -
  yum install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
  yum repolist; yum install python-virtualenv python-pip python-devel sshpass git vim-enhanced -y
  ```

2. Create the Python virtualenv and install Ansible:

  ```
  virtualenv ansible2; source ansible2/bin/activate
  pip install ansible pyrax
  ```

### Ubuntu 14+ / Debian 8

1. Install required packaged:

  ```
  sudo su -
  apt-get update; apt-get -y install python-virtualenv python-pip python-dev sshpass git vim
  ```

2. Create the Python virtualenv and install Ansible:

  ```
  virtualenv ansible2; source ansible2/bin/activate
  pip install ansible pyrax
  ```


## Clone the repository

On the same build node / workstation, run the following:

```
cd; git clone https://github.com/rackerlabs/ansible-hadoop
```


## Set the inventory

There are three types of nodes:

1. `master-nodes` are nodes running the master Hadoop services. You can specify one, two or three nodes.
 
 With two or three master nodes the HDFS NameNode will be configured in HA mode.

1. `slave-nodes` are nodes running the slave Hadoop services and store HDFS data. You can specify 0 or more nodes.
 
 By specifying no slave-nodes, the scripts will deploy a single-node HDP, similar with the Hortonworks sandbox.

1. `edge-nodes` are client only nodes and have only the client libraries installed. These are optional. 


Modify the inventory file at `~/ansible-hadoop/inventory/static` to match the desired cluster layout.

- For each node, set the `ansible_host` to the IP address that is reachable from the build node / workstation.

- Then set `ansible_user=root` and `ansible_ssh_pass` if the node allows for root user logins. If these are not set, public-key authentication will be used.

- Example for a 1 master node and 3 slave nodes cluster:

  ```
  [master-nodes]
  master01 ansible_host=192.168.0.2 ansible_user=root ansible_ssh_pass=changeme
  
  [slave-nodes]
  slave01 ansible_host=192.168.0.3 ansible_user=root ansible_ssh_pass=changeme
  slave02 ansible_host=192.168.0.4 ansible_user=root ansible_ssh_pass=changeme
  ```

- Example for installing a single-node HDP cluster on the local build node (useful if you want HDP installed on a VirtualBox / VMware VM):

  ```
  [master-nodes]
  master01 ansible_host=localhost ansible_connection=local
  ```


## Set master-nodes variables

Modify the file at `~/ansible-hadoop/playbooks/group_vars/master-nodes` to set master-nodes specific information (you can remove all the existing content from this file).

| Variable           | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| cluster_interface  | Should be set to the network device that the HDP nodes will use to communicate between them. |
| hadoop_disk        | The disk that should be mounted under `/hadoop`. The playbook will attempt to partition and format it! Remove this variable if `/hadoop` should just be a folder on the root filesystem or if the disk has already been partitioned and mounted. |
| datanode_disks     | Only used for single-nodes clusters. The disks that will be mounted under `/grid/{0..n}`. Should be set if one or more separate disk devices are used for storing HDFS data. |

- Example for using the `eth0` cluster interface and `sdb` as the disk device for `/hadoop`:

  ```
  cluster_interface: 'eth0'
  hadoop_disk: sdb
  ```

- Example for a single-node cluster with `sdb` mounted under `/hadoop` and `sdc`, `sdd`, `sde` used as data drives and mounted under `/grid/0`, `/grid/1` and `/grid/2`:

  ```
  cluster_interface: 'eth0'
  hadoop_disk: sdb
  datanode_disks: ['sdc', 'sdd', 'sde']
  ```


## Set slave-nodes variables

Modify the file at `~/ansible-hadoop/playbooks/group_vars/slave-nodes` to set slave-nodes specific information (you can remove all the existing content from this file).

| Variable           | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| cluster_interface  | Should be set to the network device that the HDP nodes will use to communicate between them. |
| datanode_disks     | The disks that will be mounted under `/grid/{0..n}`. Should be set if one or more separate disk devices are used for storing HDFS data. Remove this variable if HDFS data should be stored on the root filesystem or if the disks have already been partitioned and mounted under `/grid/{0..n}`. |

- Example for using the `eth0` cluster interface and `sdb`, `sdc`, `sdd` as the disk devices that will be mounted under `/grid/0`, `/grid/1` and `/grid/2`:

  ```
  cluster_interface: 'eth0'
  datanode_disks: ['sdb', 'sdc', 'sdd']
  ```


## Set edge-nodes variables

Optionally, if edge nodes are used, modify the file at `~/ansible-hadoop/playbooks/group_vars/edge-nodes` to set edge-nodes specific information (you can remove all the existing content from this file).

The same guidelines as for the master nodes above can be used here.


## Set the global variables

Modify the file at `~/ansible-hadoop/playbooks/group_vars/all` to set the cluster configuration.

The following table will describe the most important variables:

| Variable          | Description                                                         |
| ----------------- | ------------------------------------------------------------------- |
| cluster_name      | The name of the HDP cluster.                                        |
| hdp_version       | The HDP major version that should be installed.                     |
| admin_password    | This is the Ambari admin user password.                             |
| services_password | This is a password used by everything else (like hive's database).  |
| install_*         | Set these to true in order to install the respective HDP component. |


## Bootstrapping

The first step is to run the bootstrapping script that will setup the prerequisites on the cluster nodes.

```
cd ~/ansible-hadoop/ && bash bootstrap_static.sh
```


## HDP Installation

Then run the script that will install Ambari and build the cluster using Ambari Blueprints:

```
cd ~/ansible-hadoop/ && bash hortonworks_static.sh
```


## Login to Ambari

Once you are at this point you can see progress by accessing the Ambari interface.

The Ambari server runs on the last master-node and be accessed on port 8080.

