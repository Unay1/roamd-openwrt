#!/bin/sh
#
# Sign every OpenWrt 25.12 APK produced by the SDK, then verify it.
#
# apk-tools 3.0.5 does not sign packages during mkpkg. adbsign rewrites each
# package and appends a signature. The global --allow-untrusted is required
# because the freshly built package is unsigned before this operation.
#
# Usage: sh scripts/sign-apks.sh <sdk-dir> <package-dir> <private-key> <public-keys-dir>
set -eu

sdk_dir=${1:?SDK directory is required}
package_dir=${2:?package directory is required}
private_key=${3:?private signing key is required}
public_keys_dir=${4:?public keys directory is required}

apk="${sdk_dir}/staging_dir/host/bin/apk"

[ -x "${apk}" ] || {
  echo "ERROR: apk tool not found: ${apk}" >&2
  exit 1
}
[ -f "${private_key}" ] || {
  echo "ERROR: private signing key not found: ${private_key}" >&2
  exit 1
}
[ -d "${public_keys_dir}" ] || {
  echo "ERROR: public keys directory not found: ${public_keys_dir}" >&2
  exit 1
}

packages=$(find "${package_dir}" -maxdepth 1 -type f -name '*.apk' | sort)
[ -n "${packages}" ] || {
  echo "ERROR: no APK packages found in ${package_dir}" >&2
  exit 1
}

printf '%s\n' "${packages}" | while IFS= read -r package; do
  echo "Signing: ${package}"
  "${apk}" --allow-untrusted adbsign \
    --sign-key "${private_key}" --reset-signatures "${package}"
done

printf '%s\n' "${packages}" | while IFS= read -r package; do
  echo "Verifying: ${package}"
  "${apk}" --keys-dir "${public_keys_dir}" verify -v "${package}"
done
