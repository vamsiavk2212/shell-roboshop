#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0e757d5b59ac720a8"
INSTANCES=("MONGODB" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z08593462361SABLJQHSK"
DOMAIN_NAME="daws100s.site"

for instance in "${INSTANCES[@]}"
do
    echo "Launching instance: $instance"
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    echo "Waiting for instance $INSTANCE_ID to be in 'running' state..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)
    fi

    echo "$instance instance ($INSTANCE_ID) IP address: $IP"
done
