#! /bin/bash

#
# Create a generic release
#
#
#

# -- identify component as argument and version

COMPONENT=$1
VERSION=$( echo ${GITHUB_REF_NAME} | tr -d v )


# -- check for assets 

if [ ! -d /assets ]; then
  echo "No assets directory found"
  exit 0
fi


if [ ! -n "$(ls -A /assets)" ]; then 
  echo "No assets to release"
  exit 0
fi



# -- create release as draft

echo "-- create draft release"

RELEASE=$( curl -sS -L -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${ACTION_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" \
                ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/releases \
               -d "{\"tag_name\":\"${GITHUB_REF_NAME}\", \"name\":\"${GITHUB_REF_NAME}\", \"body\":\"Release for ${COMPONENT} version ${VERSION}\",\"draft\":true, \"prerelease\":true, \"generate_release_notes\":false}" )


# -- identify release ID
RELEASE_ID=$( echo ${RELEASE} | jq -r .id )


# -- identify upload url
RELEASE_UPLOAD_URL=$( echo ${RELEASE} | jq -r .upload_url )
RELEASE_UPLOAD_URL="${RELEASE_UPLOAD_URL%\{*}"


# -- add assets

echo "-- add release assets"

for XFILE in $(ls /assets); do

   echo "   adding file ${XFILE}"

   curl -sS -L -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${ACTION_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/octet-stream" \
           --data-binary @/assets/${XFILE}  \
           $RELEASE_UPLOAD_URL?name=${XFILE}

done



# -- set release as final

echo "-- add release assets"

curl -sS -L -X PATCH -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${ACTION_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" \
                       ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/releases/${RELEASE_ID} \
                      -d "{\"draft\":false, \"prerelease\":false, \"make_latest\":true}" 


