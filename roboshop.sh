AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0e757d5b59ac720a8" 
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z08593462361SABLJQHSK" 
DOMAIN_NAME="daws100s.site" 

for instance in ${INSTANCES[@]}
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0e757d5b59ac720a8 --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi
    echo "$instance IP address: $IP"


    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
            "Comment": "Creating or Updating a record set for cognito endpoint"
            ,"Changes": [{
            "Action"              : "UPSERT"
            ,"ResourceRecordSet"  : {
                "Name"              : "'$instance'.'$DOMAIN_NAME'"
                ,"Type"             : "A"
                ,"TTL"              : 1
                ,"ResourceRecords"  : [{
                    "Value"         : "'$IP'"
                }]
            }
            }]
    }'
done