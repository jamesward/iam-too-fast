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

declare email=$(gcloud iam service-accounts create $name \
    --display-name="$name" \
    --project=$project \
    --format="get(email)")

#echo "Trying to list compute instances, but this should fail"
#gcloud compute instances list \
#    --impersonate-service-account=$email

echo "Giving the service account the compute.viewer role"
gcloud projects add-iam-policy-binding $project \
    --member=serviceAccount:$email \
    --role=roles/compute.viewer \
    --no-user-output-enabled --quiet

echo "Deploying an app on Cloud Run that needs the newly granted role"
gcloud run deploy $name \
    --project=$project \
    --platform=managed \
    --region=us-central1 \
    --image=gcr.io/cr-demo-235923/gce-list \
    --allow-unauthenticated \
    --memory=512Mi \
    --service-account=$email

echo "Trying to use the new role via gcloud"
gcloud compute instances list \
    --impersonate-service-account=$email

readonly endpoint=$(gcloud run services describe $name --platform=managed --region=us-central1 --project=$project --format="value(status.address.url)")

echo "Trying to use the new role via Cloud Run"
curl $endpoint
