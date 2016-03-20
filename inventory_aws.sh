#!/usr/bin/env bash

aws_region=$(awk -F": " '$1 == "aws_region" {print $2;exit;}' inventory/aws/group_vars/all)
cluster_name=$(awk -F": " '$1 == "cluster_name" {print $2;exit;}' playbooks/group_vars/all)

destination_variable=${destination_variable:-ip_address} ## if connecting from within the VPC then:
                                                ##   export destination=private_ip_address

cat > inventory/aws/ec2.ini <<EOL
[ec2]
regions = ${aws_region}
regions_exclude =
instance_filters = tag:environment=${cluster_name}
cache_path = ~/.ansible/tmp
cache_max_age = 1
destination_variable = ${destination_variable}
vpc_destination_variable = ${destination_variable}

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

ANSIBLE_HOST_KEY_CHECKING=False ansible -e "ansible_user=${ansible_user}" -i inventory/aws/ --list-hosts all
