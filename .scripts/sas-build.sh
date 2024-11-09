#! /bin/bash

#
# Create a SAS macro release
#
#
#

# -- identify commiit
echo "Processing commit ${GITHUB_SHA}"


# -- identify reference
echo "Reference ${GITHUB_REF}"

# -- generate release labels 
RELEASE_SHORT_LABEL=${VARS_COMPONENT}_$( echo ${GITHUB_REF_NAME} | tr -d v )
RELEASE_LONG_LABEL=${RELEASE_SHORT_LABEL}-${GITHUB_SHA}



# -- scaffolding

if [ ! -d /assets ]; then 
  echo "Assests directory does not exist"
  exit 0
fi


# -- change working directory
cd /src


# -- create assets

echo "-- create Zip asset ${RELEASE_LONG_LABEL}"

zip -r /assets/${RELEASE_LONG_LABEL}.zip $@


echo "-- create tar.gz asset ${RELEASE_LONG_LABEL}"

tar -cf /assets/${RELEASE_LONG_LABEL}.tar $@
gzip /assets/${RELEASE_LONG_LABEL}.tar



echo "-- create assets for ${RELEASE_SHORT_LABEL}"

cp /assets/${RELEASE_LONG_LABEL}.zip /assets/${RELEASE_SHORT_LABEL}.zip
cp /assets/${RELEASE_LONG_LABEL}.tar.gz /assets/${RELEASE_SHORT_LABEL}.tar.gz


