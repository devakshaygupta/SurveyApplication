#!/bin/bash

git clone ${SERVER_URL}/${REPOSITORY}

cd ${REPO_NAME}

if [ "${JOB_TYPE}" == "Validation" ]
then
    git checkout ${BRANCH}
fi

mkdir changed-sources 

sf sgd:source:delta --source force-app/main/default --to "${{ github.event.pull_request.head.sha }}" --from "${{ github.event.pull_request.base.sha }}" --output changed-sources/ --generate-delta

#Check if changed-sources contain salesforce changes
if [[ -d changed-sources/force-app/main/default ]]
then
    echo "Changes detected in following file(s) or folder(s):"
    #Loop through all the files and print the name
    for file in changed-sources/force-app/main/default/*/*
    do
        echo "${file##*/}"
    done
fi