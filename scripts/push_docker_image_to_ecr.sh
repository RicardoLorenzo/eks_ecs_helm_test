#!/bin/bash
AWS_ACCOUNT="804731442997"
AWS_REGION="eu-west-1"
APP_NAME="app-test"

if [ -z "$1" ]; then
  docker images | awk '{ print $3 " -> " $1}'
  echo
  echo "Please indicate an image ID"
  echo
  echo "$0 <image ID>"
  exit 1
fi

#aws ecr create-repository --repository-name ${APP_NAME} --region eu-west-1

PASSWORD=$(aws ecr get-login-password)
docker login -u AWS -p ${PASSWORD} ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}
docker tag $2 ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}
docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}