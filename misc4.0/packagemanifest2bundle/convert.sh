#!/usr/bin/env bash

# this command takes three variables
# 1 dir where to clone community-operators
# 2 operator name to convert
# 3 the github fork owner to push to

# here is an example invocation:
# ./convert.sh /tmp keepalived-operator raffaelespazzoli 

set -e
set -u
set -x
set -o pipefail

# base_dir is where common-operators will be downloaded.
base_dir=${1}
operator_name=${2}
community_fork=${3}
packagemanifest_dir=/tmp/${operator_name}


#git prep
rm -rf ${base_dir}/community-operators
git -C ${base_dir} clone https://github.com/operator-framework/community-operators
git -C ${base_dir}/community-operators remote add tmp https://github.com/${community_fork}/community-operators
git -C ${base_dir}/community-operators checkout -b ${operator_name}-to-bundle

# move current package manifest to tmp location
mkdir -p ${packagemanifest_dir}
rm -rf ${packagemanifest_dir}/*
cp -R ${base_dir}/community-operators/community-operators/${operator_name}/* ${packagemanifest_dir}

#clean current content
rm -f -R ${base_dir}/community-operators/community-operators/${operator_name}/*

#conversion to bundle
bundle_dir=${base_dir}/community-operators/community-operators/${operator_name}
pushd ${bundle_dir}
for dir in $(echo ${packagemanifest_dir}/*/); do
  version=$(basename ${dir})
  opm alpha bundle generate --default alpha --directory ${dir} --output-dir ${bundle_dir}/${version}
  sed  "s/${version}\///g" bundle.Dockerfile > ${bundle_dir}/${version}/Dockerfile
  sed  -i "/replaces: ${operator_name}/d" ${bundle_dir}/${version}/manifests/*.clusterserviceversion.yaml
  rm bundle.Dockerfile
done
popd

#push
git -C ${base_dir}/community-operators add .
git -C ${base_dir}/community-operators commit -m "${operator_name} conversion to bundle" -s
git -C ${base_dir}/community-operators push tmp -f

echo
echo "Now go to you community-operator fork, check the results and make a PR"