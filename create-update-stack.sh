#!/bin/bash
echo "Checking if stack exists ..."
if ! aws cloudformation describe-stacks --region "$AWS_DEFAULT_REGION" --stack-name $1 ; then

  echo -e "\nStack does not exist, creating ..."
  aws cloudformation create-stack \
    --region "$AWS_DEFAULT_REGION" \
    --stack-name $1 \
    --template-body file://main.yaml \
    --parameters \
    ParameterKey="Environment",ParameterValue="$Environment" \
    ParameterKey="BucketPath",ParameterValue="$BucketPath" \
    ParameterKey="AllowUnauthenticatedIdentities",ParameterValue="$AllowUnauthenticatedIdentities" \
    ParameterKey="AutoVerifiedAttributes",ParameterValue="$AutoVerifiedAttributes" \
    ParameterKey="MfaConfiguration",ParameterValue="$MfaConfiguration" \
    ParameterKey="AppClientName",ParameterValue="$AppClientName" \
    ParameterKey="GenerateSecret",ParameterValue="$GenerateSecret" \
    ParameterKey="DomainName",ParameterValue="$DomainName" \
    ParameterKey="CertificateArn",ParameterValue="$CertificateArn" \
    --capabilities CAPABILITY_NAMED_IAM

  echo "Waiting for stack to be created ..."
  aws cloudformation wait stack-create-complete \
    --region "$AWS_DEFAULT_REGION" \
    --stack-name $1 \

else

  echo -e "\nStack exists, attempting update ..."

  set +e
  update_output=$( aws cloudformation update-stack \
    --region "$AWS_DEFAULT_REGION" \
    --stack-name $1 \
    --template-body file://main.yaml \
    --parameters \
    ParameterKey="Environment",ParameterValue="$Environment" \
    ParameterKey="BucketPath",ParameterValue="$BucketPath" \
    ParameterKey="AllowUnauthenticatedIdentities",ParameterValue="$AllowUnauthenticatedIdentities" \
    ParameterKey="AutoVerifiedAttributes",ParameterValue="$AutoVerifiedAttributes" \
    ParameterKey="MfaConfiguration",ParameterValue="$MfaConfiguration" \
    ParameterKey="AppClientName",ParameterValue="$AppClientName" \
    ParameterKey="GenerateSecret",ParameterValue="$GenerateSecret" \
    ParameterKey="DomainName",ParameterValue="$DomainName" \
    ParameterKey="CertificateArn",ParameterValue="$CertificateArn" \
    --capabilities CAPABILITY_NAMED_IAM  2>&1)
  status=$?
  set -e

  echo "$update_output"

  if [ $status -ne 0 ] ; then

    # Don't fail for no-op update
    if [[ $update_output == *"ValidationError"* && $update_output == *"No updates"* ]] ; then
      echo -e "\nFinished create/update - no updates to be performed"
      exit 0
    else
      exit $status
    fi

  fi

  echo "Waiting for stack update to complete ..."
  aws cloudformation wait stack-update-complete \
    --region "$AWS_DEFAULT_REGION" \
    --stack-name $1 \

fi

echo "Finished create/update successfully!"