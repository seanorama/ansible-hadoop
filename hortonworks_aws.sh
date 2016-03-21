#!/usr/bin/env bash

#export AWS_ACCESS_KEY_ID="$(grep -i AWS_ACCESS_KEY_ID ~/.aws/credentials | cut -d= -f2 | xargs)"
#export AWS_SECRET_ACCESS_KEY="$(grep -i AWS_SECRET_ACCESS_KEY ~/.aws/credentials | cut -d= -f2 | xargs)"

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/aws/ playbooks/hortonworks.yml

