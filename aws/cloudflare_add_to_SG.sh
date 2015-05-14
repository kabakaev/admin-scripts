#!/bin/bash -x
# How to add all cloudflare IPs to an AWS SG:
my_SG_id=$1
for cloudflare_ip in $(curl https://www.cloudflare.com/ips-v4)
do
  aws ec2 authorize-security-group-ingress --group-id $my_SG_id --protocol tcp --port 80 --cidr $cloudflare_ip
  aws ec2 authorize-security-group-ingress --group-id $my_SG_id --protocol tcp --port 443 --cidr $cloudflare_ip
done
