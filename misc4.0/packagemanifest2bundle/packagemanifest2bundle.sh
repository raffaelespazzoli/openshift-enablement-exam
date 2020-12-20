### 
# exoected variables:
#PACKAGEMANIFEST_DIR
#BUNDLE_DIR
#OPERATOR_NAME

mkdir -p ${BUNDLE_DIR}
pushd ${BUNDLE_DIR}
for dir in $(echo ${PACKAGEMANIFEST_DIR}/*/); do
  VERSION=$(basename ${dir})
  opm alpha bundle generate --default alpha --directory ${dir} --output-dir ${BUNDLE_DIR}/${VERSION}
  sed  "s/${VERSION}\///g" bundle.Dockerfile > ${BUNDLE_DIR}/${VERSION}/Dockerfile
  sed  -i "/replaces: ${OPERATOR_NAME}/d" ${BUNDLE_DIR}/${VERSION}/manifests/*.clusterserviceversion.yaml
  rm bundle.Dockerfile
done
popd
  