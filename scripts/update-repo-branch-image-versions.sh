#!/usr/bin/env bash

set -o errexit
set -o xtrace

if [ "$#" -ne 1 ]; then
  echo "Illegal number of arguments. branch is required." >/dev/stderr
  exit 1
fi

version=$1
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

func replace_images_versions_in_longhorn_images_txt() {
  local input_file="$1"
  local version="$2"

  local output_file="${input_file}.new"

  if [ -z "$input_file" ] || [ -z "$version" ]; then
    echo "Usage: replace_longhorn_images <input_file> <version>"
    return 1
  fi

  # Read the input file line by line
  while IFS= read -r line; do
    modified=false
    for img in "${images[@]}"; do
      if [[ "$line" == *"$img"* ]]; then
        # Ensure the image tag is replaced only if it exists
        if [[ "$line" =~ $img(:[^ ]*)? ]]; then
          line=$(echo "$line" | sed -E "s|$img(:[^ ]*)?|$img:$version|")
          modified=true
          break
        fi
      fi
    done

    # Write the (possibly modified) line to the output file
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

replace_images_versions_in_longhorn_images_txt "deploy/longhorn-images.txt" "${version}"

git add "deploy/longhorn-images.txt"
git commit -s -m "chore(version): update version file to ${version}"

git status

# echo ${version} >version
#  git add version
#  git commit -s -m "chore(version): update version file to ${version}"
#  git push -u origin HEAD
popd

popd
