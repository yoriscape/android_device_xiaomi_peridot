#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=peridot
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        odm/etc/camera/enhance_motiontuning.xml|odm/etc/camera/motiontuning.xml|odm/etc/camera/night_motiontuning.xml)
            sed -i 's/xml=version/xml version/g' "${2}"
            ;;
        system_ext/etc/vintf/manifest/vendor.qti.qesdsys.service.xml)
            sed -i '1,6d' "${2}"
            ;;
        vendor/etc/init/hw/init.batterysecret.rc)
            sed -i s/seclabel\ u:r:batterysecret:s0//g "${2}"
            ;;
        vendor/etc/init/hw/init.mi_thermald.rc)
            sed -i s/seclabel\ u:r:mi_thermald:s0//g "${2}"
            ;;
        vendor/etc/init/mi_ric.rc)
            sed -i s/seclabel\ u:r:mi_ric:s0//g "${2}"
            ;;
        vendor/etc/init/init.mfp-daemon.aidl.rc)
            sed -i s/seclabel\ u:r:vendor_mfp-daemon:s0//g "${2}"
            ;;
        vendor/etc/init/hw/init.mi_ambient.rc)
            sed -i s/seclabel\ u:r:mi_ambient:s0//g "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
