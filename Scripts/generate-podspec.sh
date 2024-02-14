#!/bin/bash

set -euo pipefail
SCRIPT_NAME="$(basename $0)"


# Functions
# #########

# Arg1: Mode (full, usage_only). Defaults to 'full'.
print_usage() {
    echo "Usage: ${SCRIPT_NAME} [VERSION]"
    if [[ "${1:-full}" == 'full' ]]; then
        echo ''
        echo 'Generates the podspec file for the current project.'
        echo 'Platform requirements (min SDKs), version are read from the xcconfig files.'
        echo 'If called with VERSION, the script verifies that the current MARKETING_VERSION in the xcconfig matches VERSION.'
        echo ''
        echo 'Examples:'
        echo "$ ${SCRIPT_NAME}          # Gemerates podspec without verifying the MARKETING_VERSION against a given constant."
        echo "$ ${SCRIPT_NAME} 1.2.3    # Generates podspec and verifies that MARKETING_VERSION is 1.2.3."
    fi
}

# Arg1: Config variable name
# Arg2: Config value pattern (regex) - must escape forward slashes (used as sed separator)
# Arg3: Config file path
read_config_var() {
    sed -nE "s/^ *${1} *= *(${2}) *$/\1/p" "${3}"
    return $?
}


# Parse arguments
# ###############
VERSION_TO_VERIFY=''
if [[ $# -gt 0 ]]; then
    if [[ $# -eq 1 ]]; then
        if [[ $1 == '--help' ]] || [[ $1 == '-h' ]]; then
            print_usage 'full'
            exit 0
        fi
        VERSION_TO_VERIFY="$1"
    else
        echo 'Invalid number of arguments!'
        echo 'For more information use --help.'
        echo ''
        print_usage 'usage_only'
        exit -1
    fi
fi


# Define variables
# ################
SHARED_XCCONFIG_FILE='./Configs/Module-Shared.xcconfig'
# We define separate vars here in case we ever split it up.
VERSION_XCCONFIG_FILE="${SHARED_XCCONFIG_FILE}"
SDKS_XCCONFIG_FILE="${SHARED_XCCONFIG_FILE}"

VERSION_CONFIG_VAR='MARKETING_VERSION'
MACOS_SDK_CONFIG_VAR='MACOSX_DEPLOYMENT_TARGET'
IOS_SDK_CONFIG_VAR='IPHONEOS_DEPLOYMENT_TARGET'
TVOS_SDK_CONFIG_VAR='TVOS_DEPLOYMENT_TARGET'
WATCHOS_SDK_CONFIG_VAR='WATCHOS_DEPLOYMENT_TARGET'


# Read files
# ##########
echo 'Reading config...'
pushd "$(dirname $0)/../" > /dev/null

CURRENT_VERSION="$(read_config_var "${VERSION_CONFIG_VAR}" '[0-9]+\.[0-9]+\.[0-9]+' "${VERSION_XCCONFIG_FILE}")"

MACOS_SDK="$(read_config_var "${MACOS_SDK_CONFIG_VAR}" '[0-9]+\.[0-9]+' "${SDKS_XCCONFIG_FILE}")"
IOS_SDK="$(read_config_var "${IOS_SDK_CONFIG_VAR}" '[0-9]+\.[0-9]+' "${SDKS_XCCONFIG_FILE}")"
TVOS_SDK="$(read_config_var "${TVOS_SDK_CONFIG_VAR}" '[0-9]+\.[0-9]+' "${SDKS_XCCONFIG_FILE}")"
WATCHOS_SDK="$(read_config_var "${WATCHOS_SDK_CONFIG_VAR}" '[0-9]+\.[0-9]+' "${SDKS_XCCONFIG_FILE}")"

SUPPORTED_SWIFT_VERSIONS=''
for SPM_PKG_DEF in Package@swift-*.swift; do
    SWIFT_VERSION="$(echo "${SPM_PKG_DEF}" | sed -E 's/^Package@swift-([0-9]+\.[0-9]+)\.swift$/\1/g')"
    if [[ -n "${SWIFT_VERSION}" ]] && [[ "${SWIFT_VERSION}" != "${SPM_PKG_DEF}" ]]; then
        # We add the comma to the end here, since we will add the last version at the end.
        SUPPORTED_SWIFT_VERSIONS="${SUPPORTED_SWIFT_VERSIONS}'${SWIFT_VERSION}', "
    fi
done
SUPPORTED_SWIFT_VERSIONS="${SUPPORTED_SWIFT_VERSIONS}'$(swift package tools-version | awk -F'.' '{print $1"."$2}')'"

popd > /dev/null


# Verify variables
# ################
echo 'Verifying config...'

if [[ -z "${CURRENT_VERSION}" ]]; then
    echo "Could not find MARKETING_VERSION in ${VERSION_XCCONFIG_FILE}!"
    exit -1
elif [[ -n "${VERSION_TO_VERIFY}" ]] && [[ "${VERSION_TO_VERIFY}" != "${CURRENT_VERSION}" ]]; then
    echo "MARKETING_VERSION in ${VERSION_XCCONFIG_FILE} is ${CURRENT_VERSION}, but ${VERSION_TO_VERIFY} was expected!"
    exit -1
fi

if [[ -z "${MACOS_SDK}" ]]; then
    echo "Could not find ${MACOS_SDK_CONFIG_VAR} in ${SDKS_XCCONFIG_FILE}!"
    exit -1
fi
if [[ -z "${IOS_SDK}" ]]; then
    echo "Could not find ${IOS_SDK_CONFIG_VAR} in ${SDKS_XCCONFIG_FILE}!"
    exit -1
fi
if [[ -z "${TVOS_SDK}" ]]; then
    echo "Could not find ${TVOS_SDK_CONFIG_VAR} in ${SDKS_XCCONFIG_FILE}!"
    exit -1
fi
if [[ -z "${WATCHOS_SDK}" ]]; then
    echo "Could not find ${WATCHOS_SDK_CONFIG_VAR} in ${SDKS_XCCONFIG_FILE}!"
    exit -1
fi

# Generate podspec
# ################
echo "Generating podspec..."
pushd "$(dirname $0)/../" > /dev/null

cat << EOF > ./CocoaLumberjack.podspec
Pod::Spec.new do |s|
  s.name     = 'CocoaLumberjack'
  s.version  = '${CURRENT_VERSION}'
  s.license  = 'BSD'
  s.summary  = 'A fast & simple, yet powerful & flexible logging framework for macOS, iOS, tvOS and watchOS.'
  s.authors  = { 'Robbie Hanson' => 'robbiehanson@deusty.com' }
  s.homepage = 'https://github.com/CocoaLumberjack/CocoaLumberjack'
  s.source   = { :git => 'https://github.com/CocoaLumberjack/CocoaLumberjack.git',
                 :tag => "#{s.version}" }

  s.description = 'It is similar in concept to other popular logging frameworks such as log4j, '   \\
                  'yet is designed specifically for objective-c, and takes advantage of features ' \\
                  'such as multi-threading, grand central dispatch (if available), lockless '      \\
                  'atomic operations, and the dynamic nature of the objective-c runtime.'

  s.cocoapods_version = '>= 1.7.0'
  s.swift_versions = [${SUPPORTED_SWIFT_VERSIONS}]

  s.osx.deployment_target     = '${MACOS_SDK}'
  s.ios.deployment_target     = '${IOS_SDK}'
  s.tvos.deployment_target    = '${TVOS_SDK}'
  s.watchos.deployment_target = '${WATCHOS_SDK}'

  s.preserve_paths = 'README.md', 'LICENSE', 'CHANGELOG.md'

  s.default_subspecs = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files         = 'Sources/CocoaLumberjack/**/*.{h,m}'
    ss.private_header_files = 'Sources/CocoaLumberjack/DD*Internal.{h}'
    ss.resource_bundles     = {
        'CocoaLumberjackPrivacy' => ['Sources/CocoaLumberjack/PrivacyInfo.xcprivacy']
    }
  end

  s.subspec 'Swift' do |ss|
    ss.dependency 'CocoaLumberjack/Core'
    ss.source_files = 'Sources/CocoaLumberjackSwift/**/*.swift', 'Sources/CocoaLumberjackSwiftSupport/include/**/*.{h}'
  end
end
EOF

popd > /dev/null
