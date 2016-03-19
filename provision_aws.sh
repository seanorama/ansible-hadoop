#!/usr/bin/env bash

ansible-playbook -i inventory/localhost playbooks/provision_aws.yml -vvvv
