#!/bin/bash

##  Copyright (c) MediaArea.net SARL. All Rights Reserved.
##
##  Use of this source code is governed by a BSD-style license that can
##  be found in the License.html file in the root of the source tree.
##

set -e # fail on any error

#-----------------------------------------------------------------------
# Setup
release_directory="$(readlink -f "$(dirname "${BASH_SOURCE}")")"
root_directory="$(readlink -f "${release_directory}/../../../")"
build_directory="${root_directory}/build"
output_directory="${root_directory}/output"

build_type="${1:-static}"

version="$(<"${release_directory}/version.txt")"
build_options="$(<"${release_directory}/configure_options.txt")"

macos_version_min="10.15"

if [ "${build_type}" == "static" ] ; then
    build_options="${build_options} --enable-static --disable-shared"
else
    build_options="${build_options} --disable-static --enable-shared"
fi
build_options="${build_options} --extra-cflags=-mmacosx-version-min=${macos_version_min} --extra-cxxflags=-mmacosx-version-min=${macos_version_min} --extra-ldflags=-mmacosx-version-min=${macos_version_min} --extra-ldflags=-Wl,-headerpad_max_install_names --install-name-dir=@rpath"

mkdir -p ${output_directory}/{x86_64,arm64}/{bin,lib/meson,share,include}


cat <<EOF > "${output_directory}/x86_64/lib/meson/x86_64-darwin.ini"
[binaries]
c = 'clang'
cpp = 'clang++'
strip = 'strip'
pkg-config = 'pkg-config'
cmake = 'cmake'

[host_machine]
system='darwin'
cpu_family='x86_64'
cpu='x86_64'
endian='little'

[built-in options]
c_args = ['-arch', 'x86_64', '-mmacosx-version-min=${macos_version_min}']
cpp_args = ['-arch', 'x86_64', '-mmacosx-version-min=${macos_version_min}']
c_link_args = ['-arch', 'x86_64', '-mmacosx-version-min=${macos_version_min}']
cpp_link_args = ['-arch', 'x86_64', '-mmacosx-version-min=${macos_version_min}']
EOF

cat <<EOF > "${output_directory}/arm64/lib/meson/arm64-darwin.ini"
[binaries]
c = 'clang'
cpp = 'clang++'
strip = 'strip'
pkg-config = 'pkg-config'
cmake = 'cmake'

[host_machine]
system='darwin'
cpu_family='aarch64'
cpu='aarch64'
endian='little'

[built-in options]
c_args = ['-arch', 'arm64', '-mmacosx-version-min=${macos_version_min}']
cpp_args = ['-arch', 'arm64', '-mmacosx-version-min=${macos_version_min}']
c_link_args = ['-arch', 'arm64', '-mmacosx-version-min=${macos_version_min}']
cpp_link_args = ['-arch', 'arm64', '-mmacosx-version-min=${macos_version_min}']
EOF

export MAKEOPTS=-j$(($(sysctl -n hw.logicalcpu)+1))

#-----------------------------------------------------------------------
# Cleanup
rm -f "${root_directory}/FFmpeg_Bin_${version}_Mac_Static_universal.zip"
rm -f "${root_directory}/FFmpeg_Dev_${version}_Mac_Static_universal.zip"
rm -f "${root_directory}/FFmpeg_Bin_${version}_Mac_Shared_universal.zip"
rm -f "${root_directory}/FFmpeg_Dev_${version}_Mac_Shared_universal.zip"

#-----------------------------------------------------------------------
# Build dependencies
mkdir -p "${build_directory}/freetype"
pushd "${build_directory}/freetype"
    for arch in x86_64 arm64 ; do
        mkdir -p "${arch}"
        pushd "${arch}"
        (
            export PKG_CONFIG_PATH="${output_directory}/${arch}/lib/pkgconfig"
            meson setup --cross-file "${output_directory}/${arch}/lib/meson/${arch}-darwin.ini" --prefix "${output_directory}/${arch}" --default-library=static -Dzlib=internal -Dzlib=internal -Dbzip2=disabled -Dpng=disabled -Dharfbuzz=disabled -Dbrotli=disabled "${root_directory}/freetype"
            ninja install
        )
        popd
    done
popd

mkdir -p "${build_directory}/harfbuzz"
pushd "${build_directory}/harfbuzz"
    for arch in x86_64 arm64 ; do
        mkdir -p "${arch}"
        pushd "${arch}"
        (
            export PKG_CONFIG_PATH="${output_directory}/${arch}/lib/pkgconfig"
            meson setup --cross-file "${output_directory}/${arch}/lib/meson/${arch}-darwin.ini" --prefix "${output_directory}/${arch}" --default-library=static  -Dglib=disabled -Dgobject=disabled -Dcairo=disabled -Dchafa=disabled -Dicu=disabled -Dgraphite=disabled -Dgraphite2=disabled -Dgdi=disabled -Ddirectwrite=disabled -Dcoretext=disabled -Dwasm=disabled -Dtests=disabled -Dintrospection=disabled -Ddocs=disabled -Ddoc_tests=false -Dutilities=disabled "${root_directory}/harfbuzz"
            ninja install
        )
        popd
    done
popd

mkdir -p "${build_directory}/fribidi"
pushd "${build_directory}/fribidi"
    for arch in x86_64 arm64 ; do
        mkdir -p "${arch}"
        pushd "${arch}"
        (
            export PKG_CONFIG_PATH="${output_directory}/${arch}/lib/pkgconfig"
            meson setup --cross-file "${output_directory}/${arch}/lib/meson/${arch}-darwin.ini" --prefix "${output_directory}/${arch}" --default-library=static -Dbin=false -Ddocs=false -Dtests=false "${root_directory}/fribidi"
            ninja install
        )
        popd
    done
popd

mkdir -p "${build_directory}/ass"
pushd "${build_directory}/ass"
    for arch in x86_64 arm64 ; do
        mkdir -p "${arch}"
        pushd "${arch}"
        (
            export PKG_CONFIG_PATH="${output_directory}/${arch}/lib/pkgconfig"
            meson setup --cross-file "${output_directory}/${arch}/lib/meson/${arch}-darwin.ini" --prefix "${output_directory}/${arch}" --default-library=static -Dasm=enabled -Dfontconfig=disabled -Dlibunibreak=disabled -Dcoretext=enabled -Dcompare=disabled -Dprofile=disabled -Dtest=disabled -Dfuzz=disabled -Dcheckasm=disabled "${root_directory}/ass"
            ninja install
        )
        popd
    done
popd

mkdir -p "${build_directory}/openh264"
pushd "${build_directory}/openh264"
    for arch in x86_64 arm64 ; do
        mkdir -p "${arch}"
        pushd "${arch}"
        (
            export PKG_CONFIG_PATH="${output_directory}/${arch}/lib/pkgconfig"
            meson setup --cross-file "${output_directory}/${arch}/lib/meson/${arch}-darwin.ini" --prefix "${output_directory}/${arch}" --default-library=static -Dtests=disabled "${root_directory}/openh264"
            ninja install
        )
        popd
    done
popd

mkdir -p "${build_directory}/vulkan-headers"
pushd "${build_directory}/vulkan-headers"
    for arch in x86_64 arm64 ; do
        mkdir -p "${arch}"
        pushd "${arch}"
        ( 
            export PKG_CONFIG_PATH="${output_directory}/${arch}/lib/pkgconfig"
            cmake -GNinja -DCMAKE_OSX_DEPLOYMENT_TARGET=${macos_version_min} -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=${arch} -DCMAKE_INSTALL_PREFIX="${output_directory}/${arch}" -S"${root_directory}/vulkan-headers"
            ninja install
        )
        popd
    done
popd

mkdir -p "${build_directory}/sdl"
pushd "${build_directory}/sdl"
    for arch in x86_64 arm64 ; do
        mkdir -p "${arch}"
        pushd "${arch}"
        (
            export PKG_CONFIG_PATH="${output_directory}/${arch}/lib/pkgconfig"
            cmake -GNinja -DCMAKE_OSX_DEPLOYMENT_TARGET=${macos_version_min} -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=${arch} -DCMAKE_INSTALL_PREFIX="${output_directory}/${arch}" -DSDL_STATIC=ON -DSDL_SHARED=OFF -S"${root_directory}/sdl"
            ninja install
        )
        popd
    done
popd

#-----------------------------------------------------------------------
# Get Vulkan runtime
mkdir -p "${build_directory}/vulkan-sdk"
pushd "${build_directory}/vulkan-sdk"
    curl -LO https://sdk.lunarg.com/sdk/download/latest/mac/vulkan_sdk.zip
    unzip -q vulkan_sdk.zip -d installer
    installer_dat="$(find installer -path '*/Contents/Resources/installer.dat' -print -quit)"
    if [ -z "${installer_dat}" ] ; then
        echo "Vulkan SDK installer.dat not found"
        exit 1
    fi

    # The installer is a Qt resource containing two embedded 7z archives.
    # Locate the one with the Vulkan runtime so this remains independent of
    # offsets and packager details in future SDK releases.
    vulkan_archive=
    while IFS=: read -r archive_offset _ ; do
        tail -c +$((archive_offset + 1)) "${installer_dat}" > embedded.7z
        if tar -tf embedded.7z 2>/dev/null | grep -qx 'macOS/lib/libvulkan_kosmickrisp.dylib' ; then
            vulkan_archive="${PWD}/embedded.7z"
            break
        fi
    done < <(LC_ALL=C grep -aob $'\x37\x7a\xbc\xaf\x27\x1c' "${installer_dat}")

    if [ -z "${vulkan_archive}" ] ; then
        echo "Vulkan runtime archive not found in the SDK installer"
        exit 1
    fi

    tar -xf "${vulkan_archive}" 'macOS/lib/libvulkan*' 'macOS/share/vulkan/icd.d/libkosmickrisp_icd.json'
    rm -f embedded.7z
popd

# Copy DeckLinkSDK include files
pushd "${root_directory}/ffmpeg"
    for arch in x86_64 arm64 ; do
        cp -r DeckLinkSDK/Mac/include/* "${output_directory}/${arch}/include"
    done
popd

#-----------------------------------------------------------------------
# Build ffmpeg
mkdir -p "${build_directory}/ffmpeg"
pushd "${build_directory}/ffmpeg"
    for arch in x86_64 arm64 ; do
        mkdir -p "${arch}"
        pushd "${arch}"
        (
            export PKG_CONFIG_PATH="${output_directory}/${arch}/lib/pkgconfig"
            arch -${arch} ${root_directory}/ffmpeg/configure --prefix="${output_directory}/${arch}" ${build_options} --extra-cflags="-arch ${arch}" --extra-cxxflags="-arch ${arch}" --extra-ldflags="-arch ${arch}" --extra-ldflags="-lc++" --extra-cflags="-I${output_directory}/${arch}/include" --extra-cxxflags="-I${output_directory}/${arch}/include"
            make install
        )
        popd
    done
popd

#-----------------------------------------------------------------------
# Package
pushd "${output_directory}"
    mkdir -p universal/{bin,lib,share,include,patches}
    vulkan_runtime_directory="${output_directory}/universal/lib/ffmpeg-ma/lib"
    mkdir -p "${vulkan_runtime_directory}"
    cp -P "${build_directory}"/vulkan-sdk/macOS/lib/libvulkan*.dylib "${vulkan_runtime_directory}/"
    cp -L "${build_directory}/vulkan-sdk/macOS/share/vulkan/icd.d/libkosmickrisp_icd.json" "${vulkan_runtime_directory}/"
    sed -i '' 's|"library_path": ".*"|"library_path": "./libvulkan_kosmickrisp.dylib"|' "${vulkan_runtime_directory}/libkosmickrisp_icd.json"

    for lib in x86_64/lib/*.a ; do
        if [ ! -f "${lib}" ] ; then
            continue
        fi
        lipo -create x86_64/lib/$(basename ${lib}) arm64/lib/$(basename ${lib}) -output universal/lib/$(basename ${lib})
    done

    for lib in x86_64/lib/*.dylib ; do
        if [ ! -f "${lib}" ] || [ -L "${lib}" ] ; then
            continue
        fi
        lipo -create x86_64/lib/$(basename ${lib}) arm64/lib/$(basename ${lib}) -output universal/lib/$(basename ${lib})
    done

    # recreate the version symlinks
    for lib in x86_64/lib/*.dylib ; do
        if [ ! -L "${lib}" ] ; then
            continue
        fi
        ln -sf "$(basename "$(readlink "${lib}")")" "universal/lib/$(basename ${lib})"
    done

    for bin in x86_64/bin/ff* ; do
        if [ ! -f "${bin}" ] ; then
            continue
        fi
        lipo -create x86_64/bin/$(basename ${bin}) arm64/bin/$(basename ${bin}) -output universal/bin/$(basename ${bin})
    done

    for bin in universal/bin/ff* ; do
        if [ ! -f "${bin}" ] || [ -L "${bin}" ] ; then
            continue
        fi
        install_name_tool -add_rpath "@executable_path/../lib" "${bin}"
        install_name_tool -add_rpath "@executable_path/../lib/ffmpeg-ma/lib" "${bin}"
        if [ "${build_type}" != "static" ] ; then
            install_name_tool -add_rpath "/usr/local/lib" "${bin}"
            install_name_tool -add_rpath "/opt/homebrew/lib" "${bin}"
        fi
    done

    if [ "${build_type}" != "static" ] ; then
        for lib in universal/lib/*.dylib ; do
            if [ ! -f "${lib}" ] || [ -L "${lib}" ] ; then
                continue
            fi
            install_name_tool -add_rpath "@loader_path" "${lib}"
            install_name_tool -add_rpath "/usr/local/lib" "${lib}"
            install_name_tool -add_rpath "/opt/homebrew/lib" "${lib}"
        done
    fi

    cp -r x86_64/share/ffmpeg universal/share
    cp -r x86_64/include/lib{av*,sw*} universal/include
    cp "${root_directory}"/ffmpeg/patches/*.patch universal/patches

    if [ "${build_type}" != "static" ] ; then
        rm -f universal/lib/*.a
    fi

    cp "${root_directory}/ffmpeg/COPYING.GPLv3" universal/LICENSE.txt
    cp "${root_directory}/ffmpeg/patches/Release/ReadMe.txt" universal/README.txt
    cp "${root_directory}/ffmpeg/patches/Release/HowToGPU.mac.txt" universal/HowToGPU.txt

    patches_list="$(cd universal/patches && printf '%s\\\n ' *.patch)"
    options_list="$(printf '%s\\\n ' ${build_options})"

    sed -i '' "s|%VERSION%|${version}|g" universal/README.txt
    sed -i '' "s|%BUILD_TYPE%|${build_type}|g" universal/README.txt
    sed -i '' "s|%PACKAGE_TYPE%|binaries|g" universal/README.txt
    sed -i '' "s|%BUILD_ARCH%|x86_64 and arm64|g" universal/README.txt
    sed -i '' "s|%BUILD_OS%|macOS|g" universal/README.txt
    sed -i '' "s|%PATCHES%|${patches_list%???}|g" universal/README.txt
    sed -i '' "s|%BUILD_OPTIONS%|${options_list%???}|g" universal/README.txt

    if [ -n "${MACOS_CODESIGN_IDENTITY}" ] ; then
        for binary in universal/bin/ff* universal/lib/*.dylib universal/lib/ffmpeg-ma/lib/*.dylib ; do
            if [ ! -f "${binary}" ] || [ -L "${binary}" ] ; then
                continue
            fi
            codesign --force --options runtime --timestamp --sign "${MACOS_CODESIGN_IDENTITY}" "${binary}"
        done
    fi

    pushd universal
        if [ "${build_type}" == "shared" ] ; then
            zip -r -y ../../FFmpeg_Bin_${version}_Mac_${build_type/s/S}_universal.zip LICENSE.txt README.txt HowToGPU.txt patches bin lib share -x 'share/ffmpeg/examples/*'
            sed -i '' "s/binaries/development files/g" README.txt
            zip -r -y ../../FFmpeg_Dev_${version}_Mac_${build_type/s/S}_universal.zip LICENSE.txt README.txt HowToGPU.txt patches include share/ffmpeg/examples
        else
            zip -r -y ../../FFmpeg_Bin_${version}_Mac_${build_type/s/S}_universal.zip LICENSE.txt README.txt HowToGPU.txt patches bin lib/ffmpeg-ma/lib share -x 'share/ffmpeg/examples/*'
            sed -i '' "s/binaries/development files/g" README.txt
            zip -r -y ../../FFmpeg_Dev_${version}_Mac_${build_type/s/S}_universal.zip LICENSE.txt README.txt HowToGPU.txt patches include lib share/ffmpeg/examples
        fi
    popd
popd
