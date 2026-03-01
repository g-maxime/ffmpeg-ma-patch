#!/bin/bash

##  Copyright (c) MediaArea.net SARL. All Rights Reserved.
##
##  Use of this source code is governed by a BSD-style license that can
##  be found in the License.html file in the root of the source tree.
##

set -e

#-----------------------------------------------------------------------
# Setup
release_directory="$(readlink -f "$(dirname "${BASH_SOURCE}")")"
version="${1}"
sources="ffmpeg"

if [[ -e "${version}" ]] ; then
    echo "usage: ${0} <version>"
    exit 1
fi

#-----------------------------------------------------------------------
# Cleaning

pushd "${release_directory}"
    rm -f ffmpeg-ma_${version}.tar.xz
    rm -f ffmpeg-ma_${version}.7z
popd

#-----------------------------------------------------------------------
# Get missing dependencies
pushd "${release_directory}/../../.."
    while read line; do
        directory=$(echo "${line}" | cut -d: -f1)
        url=$(echo "${line}" | cut -d: -f2-)
        env_url="${directory^^}"
        env_url="${env_url//-/_}"
        env_url="${env_url}_URL"
        if [[ -v "${env_url}" ]] ; then
            url="${!env_url}"
        fi
        if [[ -z "${directory}" || -z "${url}" ]] ; then
            continue
        fi
        if [[ ! -e "${directory}" ]] ; then
            mkdir "${directory}"
            pushd "${directory}"
                curl -LO "${url}"
                tar --extract --strip-components=1 --file=${url##*/}
                rm -f ${url##*/}
            popd   
        fi
        sources="${sources} ${directory}"
    done < "${release_directory}/dependencies.txt"
popd

#-----------------------------------------------------------------------
# Apply patches
pushd "${release_directory}/../.."
    for patch in patches/*.patch ; do
        if [ -e "${patch}" ] ; then
            patch -p1 < "${patch}"
        fi
    done
popd

#-----------------------------------------------------------------------
# Prepare sources
pushd "${release_directory}/../../.."
    rm -fr */.git
    rm -fr ffmpeg/patches/.git

    XZ_OPT=-9e tar -cJ --owner=root --group=root -f ffmpeg-ma_${version}.tar.xz ${sources}
    7za a -t7z -mx=9 -bd ffmpeg-ma_${version}.7z ${sources}
    
    mv ffmpeg-ma_${version}.tar.xz ffmpeg-ma_${version}.7z ffmpeg/patches/Release
popd
