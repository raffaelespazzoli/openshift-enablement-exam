# variables
# community fork
# OPERATOR_NAME

git -C /tmp clone https://github.com/operator-framework/community-operators
git -C /tmp/community-operators remote add tmp https://github.com/${community_fork}/community-operators
git -C /tmp/community-operators checkout -b ${OPERATOR_NAME}-to-bundle
rm -f -R /tmp/community-operators/community-operators/${OPERATOR_NAME}/*
/home/rspazzol/git/openshift-enablement-exam/misc4.0/packagemanifest2bundle/packagemanifest2bundle.sh
git -C /tmp/community-operators add .
git -C /tmp/community-operators commit -m "${OPERATOR_NAME} conversion to bundle" -s
git -C /tmp/community-operators push tmp -f