#!/bin/bash

# Date: 2019-01-30
# Version 1.0
# License Type: GNU GENERAL PUBLIC LICENSE, Version 3
# Author:
# Iroshan Kumarasinghe / https://github.com/iroshan29 / iroshan29@gmail.com

# generate a timestamp
DATE=$(date +%Y-%m-%d)

#AWS Region
REGION="eu-west-1"

if [[ -z  $REGION  ]]; then
    availabilityZone=$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone/);
    REGION=$(echo "$availabilityZone" | grep -oP "[a-z]{1,}-[a-z]{1,}-\\d{1,}");
fi

# how long to keep the AMI's
DAYS_TO_KEEP=14

# standard prefix for auto-generated AMI's
PREFIX="AMI_BackUp_Test"

#genarate AMI Name and Description for Creation
AMI_NAME="$PREFIX-$DATE"
AMI_DESCRIPTION="$PREFIX-$DATE"

# generate a timestamp for deregister AMI
ODATE=$(date -d $DAYS_TO_KEEP" days ago" +%Y-%m-%d)

#genarate AMI Name and Description for deregister
OAMI_NAME="$PREFIX-$ODATE"
OAMI_DESCRIPTION="$PREFIX-$ODATE"

printf "Requesting AMI for current instance ...\n"

INSTANCE_ID=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id);
echo "Instance ID : "$INSTANCE_ID

echo "Going to create AMI for the Instance :"$INSTANCE_ID

ami_id_name=`aws ec2 create-image --region $REGION --instance-id $INSTANCE_ID --name "$AMI_NAME" --description "$AMI_DESCRIPTION" --no-reboot`

NEW_AMI_ID=`echo $ami_id_name | awk -F'"' '{print $4}'`

if [[ -z $NEW_AMI_ID ]]; then

echo "AMI request failed!!"
else
echo "AMI request complete! AMI ID : "$NEW_AMI_ID
fi

echo "Going to Deregistering Image:"$OAMI_NAME
dreg_ami_id=`aws ec2 describe-images --region $REGION --filter Name=name,Values="$OAMI_NAME" --query 'Images[*].{ID:ImageId}' --output text`

if [[ -z $dreg_ami_id ]];
then
echo "AMI "$OAMI_NAME" does not exists!!!"
else
echo "AMI ID: "$dreg_ami_id
fi

if [[ -n $dreg_ami_id ]];then
dreg_ami_result= `aws ec2 deregister-image --image-id "$dreg_ami_id"`
fi

if [[ -z dreg_ami_result ]]; then
echo "AMI ID : "$dreg_ami_id" deregistered"
else
echo $dreg_ami_result
fi
