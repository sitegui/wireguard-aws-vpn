#!/bin/bash -e

if [[ $# -lt 6 ]]; then
  echo "Usage: $0 <AWS_REGION> <AWS_PROFILE> <AWS_SUBNET_ID> <AWS_SECURITY_GROUP_ID> <AWS_KEY_NAME> <AWS_IDENTITY_FILE>"
  exit
fi

AWS_REGION=$1
AWS_PROFILE=$2
AWS_SUBNET_ID=$3
AWS_SECURITY_GROUP_ID=$4
AWS_KEY_NAME=$5
AWS_IDENTITY_FILE=$6

export AWS_PAGER=""

CREATE_INSTANCE_RESPONSE=$(aws --profile $AWS_PROFILE --region $AWS_REGION ec2 run-instances --image-id ami-090006f29ecb2d79a --instance-type t2.micro --subnet-id $AWS_SUBNET_ID --associate-public-ip-address --ipv6-address-count 1 --security-group-ids $AWS_SECURITY_GROUP_ID --key-name $AWS_KEY_NAME)

echo "EC2 run-instances API called"

INSTANCE_ID=$(echo $CREATE_INSTANCE_RESPONSE | jq '.Instances[0].InstanceId' --raw-output)

echo "Created instance with ID: $INSTANCE_ID"

DESCRIBE_INSTANCE_RESPONSE=$(aws --profile $AWS_PROFILE --region $AWS_REGION ec2 describe-instances --instance-ids $INSTANCE_ID)

PUBLIC_IP_ADDRESS=$(echo $DESCRIBE_INSTANCE_RESPONSE | jq '.Reservations[0].Instances[0].PublicIpAddress' --raw-output)

echo "Instance's public IP address is $PUBLIC_IP_ADDRESS"

STATE_CHECKS_COUNT=1
while [ $STATE_CHECKS_COUNT -le 10 ];
do
    echo "Checking instance $INSTANCE_ID state"
    DESCRIBE_INSTANCE_RESPONSE=$(aws --profile $AWS_PROFILE --region $AWS_REGION ec2 describe-instances --instance-ids $INSTANCE_ID)
    INSTANCE_STATE=$(echo $DESCRIBE_INSTANCE_RESPONSE | jq '.Reservations[0].Instances[0].State.Name' --raw-output)
    if [[ "$INSTANCE_STATE" == "running" ]]; then
        echo -e "Instance state is \033[0;32m$INSTANCE_STATE\033[0m"
        echo "Will wait 15 seconds before attempting to SSH to it"
        sleep 15
        break
    else 
        echo -e "Instance state is \033[0;33m$INSTANCE_STATE\033[0m"
    fi
    echo "Will wait 5 seconds before checking again..."
    sleep 5
done

./vpn.sh $AWS_IDENTITY_FILE $PUBLIC_IP_ADDRESS

function tear_down {
    printf "\n\nVPN will be shutdown\n\n"
    TERMINATE_INSTANCE_RESPONSE=$(aws --profile $AWS_PROFILE --region $AWS_REGION ec2 terminate-instances --instance-ids $INSTANCE_ID)
    printf "Terminate instances call response was:\n$TERMINATE_INSTANCE_RESPONSE\n\n"
    wg-quick down wg0
    ssh-keygen -R $PUBLIC_IP_ADDRESS
}

trap tear_down EXIT

echo "Nice, the VPN is up and running. Press ctrl+c to stop it"

# waits forever
tail -f /dev/null
