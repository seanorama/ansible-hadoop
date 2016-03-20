#!/usr/bin/env bash

#export AWS_ACCESS_KEY_ID="$(grep -i AWS_ACCESS_KEY_ID ~/.aws/credentials | cut -d= -f2 | xargs)"
#export AWS_SECRET_ACCESS_KEY="$(grep -i AWS_SECRET_ACCESS_KEY ~/.aws/credentials | cut -d= -f2 | xargs)"

# Set from the environment before running, or uncomment below
ansible_user=${ansible_user:-ec2-user}
#ansible_user=centos" ## CentOS
#ansible_user="ubuntu" ## Ubuntu
#ansible_user="ec2-user" ## Amazon Linux, RedHat

inventory/aws/ec2.ini.sh
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -e "ansible_user=${ansible_user}" -i inventory/aws/ playbooks/bootstrap_aws.yml -vvvv
