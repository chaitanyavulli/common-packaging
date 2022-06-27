#!/bin/bash

set -a
source ../common-packaging/pr_creation/reviewers.vars
set +a

SLUG_DEST=$1      # vru-5g-phy                            ; lte_phy_simulation
SLUG_SRC=$2       # 5g_phy_simulation                     ; vru-4g-phy
TEXT=$3           # current-5g_phy_simulation-sha1.txt    ; mex-artifactory-location.txt
PROJECT=$4        # cd                                    ; sc

if [[ "$SLUG_DEST" =~ "5g" ]] || [[ "$SLUG_SRC" =~ "5g" ]]; then
    REVIEW_LIST=$list_5G
fi

if [[ "$SLUG_DEST" =~ "4g" ]] || [[ "$SLUG_SRC" =~ "4g" ]]; then
    REVIEW_LIST=$list_4G
fi

if [[ "$SLUG_DEST" =~ "2g" ]] || [[ "$SLUG_SRC" =~ "2g" ]]; then
    REVIEW_LIST=$list_2G
fi

COMMIT_MESSAGE=${GIT_COMMIT_MSG}
COMMIT_MESSAGE=${COMMIT_MESSAGE:0:128}
echo ${COMMIT_MESSAGE} | tr -d "\'\""

FULL_HASH=$(git rev-parse HEAD) # this is from the SLUG SRC
HASH=${FULL_HASH:0:8}
cd ../${SLUG_DEST}

git checkout -b private/${SLUG_SRC}/develop origin/develop
echo ${FULL_HASH} > ${TEXT}.txt
git add ${TEXT}.txt
git commit -m "Auto manifest update to ${HASH} ${COMMIT_MESSAGE}"
git push origin -u -f private/${SLUG_SRC}/develop

cat > /tmp/${BUILD_NUMBER}-${HASH}-datareq.json <<EOF

  {
    "title": "Auto manifest update to ${HASH} ${COMMIT_MESSAGE}",
    "description": "Auto-update-manifest",
    "state": "OPEN",
    "open": true,
    "closed": false,
    "fromRef": {
        "id": "refs\/heads\/private\/${SLUG_SRC}\/develop",
        "repository": {
            "slug": "${SLUG_DEST}",
            "name": null,
            "project": {
            "key": "${PROJECT}"
             }
         }
    },
    "toRef": {
        "id": "refs\/heads\/develop",
        "repository": {
            "slug": "${SLUG_DEST}",
            "name": null,
            "project": {
            "key": "${PROJECT}"
            }
        }
    },
    "locked": false,
    "links": {
        "self": [
            null
        ]
    },
    "reviewers": [
       $REVIEW_LIST
    ]

  }

EOF

curl -i -X POST -u ${prUser}:${prPass} -H 'Content-Type:application/json' "https://git.parallelwireless.net/rest/api/1.0/projects/${PROJECT}/repos/${SLUG_DEST}/pull-requests" -X POST --data @/tmp/${BUILD_NUMBER}-${HASH}-datareq.json
