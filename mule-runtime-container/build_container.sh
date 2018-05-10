#!/bin/bash  
image_tag=${1}
mule_version=3.9.0
repository=mule-ee-runtime-${mule_version}

docker --version
echo "Creating Mule ${mule_version} Docker Image [ repository=${repository}, image_tag=${image_tag} ] "
docker build --tag "${repository}:${image_tag}" .
echo "Docker Images Available"
docker image ls