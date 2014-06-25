#!/bin/bash
. ./config_params.sh

ERASE_DEV=0
FORMAT_DEV=0
INSTALL=0
WORKSPACE=0
DEV=/dev/sdd
LIVE_PART=${DEV}1
WORK_PART=${DEV}2
LIVE_IMG=./ubuntu-live.iso
WORK_DIR=$(pwd)
USB_KEY=/tmp/usb_key  
LIVE_DIR=/tmp/live
WORKSPACE_DIR=/tmp/workspace

usage() {
echo -e "
\e[1mUsage:\e[0m $0 options
  
\e[1mOPTIONS\e[0m

  -e, --erase
     erase the device and create partitions
  -f, --format
     format the partitions
  -d, --dev
     device path
  -i, --image
     live image iso
  -I, --install
     install the live system
  -w, --workspace
     setup the live system workspace
"
}

spin() {
  SPIN='-\|/'
  i=0
  while kill -0 $1 2> /dev/null
  do
    i=$(( (i+1)%4 ))
    printf "\b${SPIN:$i:1}"
    sleep .1
  done
  printf "\bDONE\n"
}

askCONF() {
  printf "\e[91mWARNING:\e[0m This script will erase $DEV, create two partitions
($LIVE_PART and $WORK_PART) and install the live system in ${LIVE_PART}.
Are you sure you want to continue? [N/y] "
  read c
  if [ "${c}" != "y" ]; then
    printf "\n"
    exit 0
  fi
}

cleanup() {
  cd ${WORK_DIR}

  printf "\n\e[92mCleaning up...\e[0m\n"
  [ -d "${USB_KEY}" ] && umount ${USB_KEY} && rmdir ${USB_KEY}
  [ -d "${LIVE_DIR}" ] && umount ${LIVE_DIR} && rmdir ${LIVE_DIR}
  [ -d "${WORKSPACE_DIR}" ] && umount -f ${WORKSPACE_DIR} && rmdir ${WORKSPACE_DIR}

  umount ${LIVE_PART} > /dev/null 2>&1
  umount ${WORK_PART} > /dev/null 2>&1

  exit 0
}

erase_dev() {
  if [ $(mount | grep ${DEV} | wc -l) != "0" ]; then
    printf "\n\e[91mERROR: \e[0mFailed to erase ${DEV}\n"
    printf "\e[33mHINT: \e[0mtry to umount the device\n"
    exit 1
  fi

  printf "\e[92mErasing ${DEV}\e[0m --->  "
  dd if=/dev/zero of=${DEV} bs=1024k > /dev/null 2>&1 &
  spin $!
  printf "\e[92mCreating empty msdos partition table ${DEV}\e[0m --->  "
  printf "w\n" | fdisk ${DEV} > /dev/null 2>&1 &
  spin $!
  printf "\e[92mCreating partitions on ${DEV}\e[0m --->  "
  printf "n\np\n1\n\n+2G\na\n1\nt\nc\nn\np\n2\n\n\nw\n" | fdisk ${DEV} > /dev/null 2>&1 &
  spin $!
  printf "\e[92mInstalling MBR on ${DEV}\e[0m --->  "
  install-mbr ${DEV}
  spin $!
  partprobe ${DEV}
}

format() {
  printf "\e[92mFormatting ${LIVE_PART}\e[0m --->  "
  mkfs.msdos -F32 ${LIVE_PART} > /dev/null 2>&1 &
  if [ $(mount | grep ${LIVE_PART} | wc -l) != "0" ]; then
    printf "\n\e[91mERROR: \e[0mFailed to create FAT32 filesystem on ${LIVE_PART}\n"
    printf "\e[33mHINT: \e[0mtry to umount the device\n"
    exit 1
  fi
  spin $!
  printf "\e[92mFormatting ${WORK_PART}\e[0m --->  "
  mkfs.ext3 ${WORK_PART} > /dev/null 2>&1 &
  if [ $(mount | grep ${WORK_PART} | wc -l) != "0" ]; then
    printf "\n\e[91mERROR: \e[0mFailed to create ext3 filesystem on ${WORK_PART}\n"
    printf "\e[33mHINT: \e[0mtry to umount the device\n"
    exit 1
  fi
  spin $!
}

install_image() {
  printf "\e[92mInstalling bootloader\e[0m --->  "
  syslinux -i ${LIVE_PART} > /dev/null 2>&1 &
  spin $!

  mkdir -p ${USB_KEY}
  mount ${LIVE_PART} ${USB_KEY}
  mkdir -p ${LIVE_DIR}
  mount -o loop ${LIVE_IMG} ${LIVE_DIR} > /dev/null 2>&1

  printf "\e[92mCopying files\e[0m --->  "
  cd ${LIVE_DIR}
  cp -R * ${USB_KEY} > /dev/null 2>&1 &
  spin $!
  cd ${WORK_DIR}

  printf "\e[92mConfiguring isolinux\e[0m --->  "
  #cp isolinux/* ${USB_KEY} > /dev/null 2>&1 &
  mv ${USB_KEY}/isolinux ${USB_KEY}/syslinux > /dev/null 2>&1 &
  spin $!
  mv ${USB_KEY}/syslinux/isolinux.cfg ${USB_KEY}/syslinux/syslinux.cfg

  printf "\e[92mWait for data to be written\e[0m --->  "
  sync &
  spin $!
}

configure_workspace() {
  mkdir -p ${WORKSPACE_DIR}
  mount ${WORK_PART} ${WORKSPACE_DIR}

  ./setup_workspace.sh -d
  printf "\e[92mTransferring workspace on ${WORK_PART}\e[0m --->  "
  sudo cp -r * ${WORKSPACE_DIR} > /dev/null 2>&1 &
  spin $!
  yes | ./setup_workspace.sh -e

  printf "\e[92mWait for data to be written\e[0m --->  "
  sync &
  spin $!
}

if [ $(id -u) != 0 ]; then 
  echo "You need to be root to run this script"
  exit 1
fi

if [ $# -lt 1 ]; then 
  usage
  exit 0
fi

while [ $# -gt 0 ]; do
  KEY=$1
  shift
  case $KEY in
  -e | --erase)
    ERASE_DEV=1
    ;;
  -f | --format)
    FORMAT_DEV=1
    ;;
  -I | --install)
    INSTALL=1
    ;;
  -w | --workspace)
    WORKSPACE=1
    ;;
  -d | --dev)
    DEV=$1
    shift
    ;;
  -i | --img)
    LIVE_IMG=$1
    shift
    ;;
  *)
    usage
    shift
    ;;
  esac
done

askCONF

trap cleanup SIGINT SIGTERM

[ $ERASE_DEV -eq 1 ] && erase_dev
[ $FORMAT_DEV -eq 1 ] && format
[ $INSTALL -eq 1 ] && install_image
[ $WORKSPACE -eq 1 ] && configure_workspace

cleanup

printf "\e[92mUSB drive is ready!\e[0\nm"
