#!/bin/bash

declare project=$(gcloud config get-value project)

if [ -z "$project" ]; then
  echo "Must set project: gcloud config set project BLAH"
  exit 1
fi

declare me=$(gcloud config get-value account)

echo "current user = $me"

echo "adding roles/iam.serviceAccountTokenCreator role to current user"
gcloud projects add-iam-policy-binding $project \
    --member=user:$me \
    --role=roles/iam.serviceAccountTokenCreator \
    --no-user-output-enabled --quiet

declare name="test-$(cat /dev/urandom|tr -dc 'a-z0-9'|fold -w 4|head -n 1)"

declare email=$name@$project.iam.gserviceaccount.com

echo "Creating service account $email"
gcloud iam service-accounts create $name \
    --display-name="$name"

echo "Giving the service account the compute.viewer role"
gcloud projects add-iam-policy-binding $project \
    --member=serviceAccount:$email \
    --role=roles/compute.viewer \
    --no-user-output-enabled --quiet

echo "Using the new role to list compute instances"
gcloud compute instances list \
    --impersonate-service-account=$email

echo "Deleting service account $email"
gcloud iam service-accounts delete $email \
    --no-user-output-enabled --quiet

echo "Recreating service account $email"
gcloud iam service-accounts create $name \
    --display-name="$name"

echo "Giving the service account the compute.viewer role"
gcloud projects add-iam-policy-binding $project \
    --member=serviceAccount:$email \
    --role=roles/compute.viewer \
    --no-user-output-enabled --quiet

echo "Trying to use the new role via gcloud"
gcloud compute instances list \
    --impersonate-service-account=$email \

