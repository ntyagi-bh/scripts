#!/bin/bash
#
# This script is modified version of https://github.com/bamboohealth/github-support/blob/master/remove-branch-protection.sh
# to remove protections on repeat, in batches of 100

# Set authentication
echo "Your github Personal Access Token: "
#read -s pat
pat=$1

echo "Repository you want to update: "
#read -s repo
repo=$2

echo "Getting list of Protected Branches for repo $2 ..."
# edit grep at the end for branches you want to ignore (keep protections)
branches=($(curl -X GET -H "Authorization: Bearer ${pat}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/bamboohealth/${repo}/branches\?protected=true\&per_page=100 | jq -r '.[] | .name' | grep -Ev 'master|develop|release'))
echo

# printf '%s\n' "${branches[@]}"
echo
count=${#branches[*]}
echo "Deleting Branch Protection for $count branches...."
for i in "${branches[@]}"
do
    echo "BRANCH: $i"
    resp=$(curl -s -w "%{http_code}" -X DELETE -H "Authorization: Bearer ${pat}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/bamboohealth/${repo}/branches/$i/protection)
    http_code=$(tail -n1 <<< "$resp")
    content=$(sed '$ d' <<< "$resp")
    echo "$http_code"
    if [[ $http_code -eq 200 ]]; then
        echo "SUCCESS - branch protection deleted for $i "
    elif [[ $http_code -eq 204 ]]; then
        echo "SUCCESS - no content, branch protection deleted for $i"
    else
        echo "FAILURE - branch protection not deleted for $i"
    fi
    echo
done
