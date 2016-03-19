#!/usr/bin/env bash

#export AWS_ACCESS_KEY_ID="$(grep -i AWS_ACCESS_KEY_ID ~/.aws/credentials | cut -d= -f2 | xargs)"
#export AWS_SECRET_ACCESS_KEY="$(grep -i AWS_SECRET_ACCESS_KEY ~/.aws/credentials | cut -d= -f2 | xargs)"

aws_region=$(awk -F": " '$1 == "aws_region" {print $2;exit;}' inventory/aws/group_vars/all)
cluster_name=${cluster_name:-$(grep cluster_name playbooks/group_vars/all|cut -d"'" -f2)}
vpc_destination_variable=${destination_veriable:-ip_address} ## easy override

# Set from the environment before running, or uncomment below
ansible_user=${ansible_user:-ec2-user}
#ansible_user=centos" ## CentOS
#ansible_user="ubuntu" ## Ubuntu
#ansible_user="ec2-user" ## Amazon Linux, RedHat


cat > inventory/aws/ec2.ini <<EOL
[ec2]
regions = ${aws_region}
regions_exclude =
instance_filters = tag:environment=${cluster_name}
cache_path = ~/.ansible/tmp
cache_max_age = 1
destination_variable = public_dns_name
vpc_destination_variable = ip_address

elasticache = False
rds = False
route53 = False
all_instances = False
all_rds_instances = False
all_elasticache_replication_groups = False
all_elasticache_clusters = False
all_elasticache_nodes = False

nested_groups = False
replace_dash_in_groups = True
expand_csv_tags = False
group_by_tag_keys = True
group_by_security_group = True
EOL

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -e "ansible_user=${ansible_user}" -i inventory/aws/ playbooks/bootstrap_aws.yml -vvvv
