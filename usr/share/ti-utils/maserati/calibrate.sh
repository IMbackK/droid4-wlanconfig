#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mkdir /tmp/pds
mount -o ro /dev/mmcblk1p7 /tmp/pds
if [ $? -ne 0 ]; then
    echo "Error mounting pds"
    rm -r /tmp/pds
    exit 1
fi

PDSMAC=$(wilink6calibrator get nvs_mac /tmp/pds/wifi/nvs_map.bin)

umount /tmp/pds
rm -r /tmp/pds

if [ $? -ne 0 ]; then
    echo "Error extracting mac from pds nvs"
    exit 1
fi


echo "${PDSMAC}"

CURRENTMAC=$(wilink6calibrator get nvs_mac /lib/firmware/ti-connectivity/wl128x-nvs.bin)

if [ "$PDSMAC" == "$CURRENTMAC" ]; then
    echo "Calibration already perfomed"
    exit 0
fi

PDSMAC=${PDSMAC:19}

echo ${PDSMAC}

for DEV in `ls /sys/class/net`; do
  if [ -d "/sys/class/net/$DEV/wireless" ]; then 
    break
  fi
done

echo "Calibrating ${DEV}"

rmmod /lib/modules/$(uname -r)/kernel/drivers/net/wireless/ti/wl12xx/wl12xx.ko

wilink6calibrator plt autocalibrate ${DEV} /lib/modules/$(uname -r)/kernel/drivers/net/wireless/ti/wl12xx/wl12xx.ko ${DIR}/maserati_nvs.ini /tmp/wl128x-nvs.bin ${PDSMAC}

if [ ! -f /tmp/wl128x-nvs.bin ]; then
    echo "Error calibraing device"
    exit 1
fi

rm /lib/firmware/ti-connectivity/wl128x-nvs.bin
mv /tmp/wl128x-nvs.bin /lib/firmware/ti-connectivity/wl128x-nvs.bin
insmod /lib/modules/$(uname -r)/kernel/drivers/net/wireless/ti/wl12xx/wl12xx.ko

exit 0
