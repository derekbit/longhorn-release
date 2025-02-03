#!/usr/bin/env bash

set -o errexit
set -o xtrace

if [ "$#" -ne 2 ]; then
  echo "Illegal number of arguments. branch and tag are required." >/dev/stderr
  exit 1
fi

branch=$1
tag=$2

repos_dir=.repos

images=(
  longhornio/backing-image-manager
  longhornio/longhorn-engine
  longhornio/longhorn-instance-manager
  longhornio/longhorn-manager
  longhornio/longhorn-share-manager
  longhornio/longhorn-ui
  longhornio/longhorn-cli
)

function replace_images_tags_in_longhorn_images_txt() {
  local input_file="$1"
  local tag="$2"

  local output_file="${input_file}.new"

  if [ -z "$input_file" ] || [ -z "$tag" ]; then
    echo "Usage: replace_longhorn_images <input_file> <tag>"
    return 1
  fi

  while IFS= read -r line; do
    modified=false
    for img in "${images[@]}"; do
      if [[ "$line" == *"$img"* ]]; then
        if [[ "$line" =~ $img(:[^ ]*)? ]]; then
          line=$(echo "$line" | sed -E "s|$img(:[^ ]*)?|$img:$tag|")
          modified=true
          break
        fi
      fi
    done
    echo "$line" >> "$output_file"
  done < "$input_file"

  if [ $? -eq 0 ]; then
    mv "$output_file" "$input_file"
    echo "Successfully replaced Longhorn image tags in '$input_file'."
  else
    rm -f "$output_file"
    echo "Error: Failed to replace Longhorn image tags."
    return 1
  fi
}

function teardown() {
  rm -rf $repos_dir
}
trap teardown EXIT

mkdir -p $repos_dir

pushd $repos_dir

gh repo clone derekbit/longhorn
pushd longhorn

git checkout "$branch"

replace_images_tags_in_longhorn_images_txt "deploy/longhorn-images.txt" "${tag}"

popd
popd
