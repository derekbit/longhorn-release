#!/usr/bin/env bash

set -o errexit
set -o xtrace

if [ "$#" -ne 1 ]; then
  echo "Illegal number of arguments. version are required." >/dev/stderr
  exit 1
fi

version=$1
repos_dir=.repos

repos=(
  "longhorn/longhorn-manager"
  "longhorn/longhorn-instance-manager"
  "longhorn/longhorn-engine"
  "longhorn/longhorn-share-manager"
  "longhorn/backing-image-manager"
  "longhorn/longhorn-ui"
  "longhorn/cli"
  # "longhorn/longhorn-spdk-engine" only needed since GA
)

function teardown() {
  rm -rf $repos_dir
}
trap teardown EXIT

mkdir -p $repos_dir

pushd $repos_dir
for repo in "${repos[@]}"; do
  gh repo clone "${repo}"

  pushd "${repo##*/}"
  echo ${version} > version
  git add version
  git commit -s -m "chore(version): update version file to ${version}"
  git push -u origin HEAD
  popd
done
popd
