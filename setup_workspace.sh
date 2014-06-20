#!/bin/bash
DOWNLOAD=0
CONFIGURE=0
COMPILE=0
SPIN='-\|/'

function show_help {
echo -e "
\e[1mUsage:\e[0m $0 options
  
\e[1mOPTIONS\e[0m

  -h
     Print this help message and exit
  -d
     Download sources
  -c
     Configure sources
  -C
     Compile sources
"
}

function spin {
  i=0
  while kill -0 $1 2> /dev/null
  do
    i=$(( (i+1)%4 ))
    printf "\b${SPIN:$i:1}"
    sleep .1
  done
  printf "\bDONE\n"
}

if [ $# -lt 1 ]; then
  show_help
  exit 0
fi

while getopts "hvdcC" opt; do
  case "$opt" in
  h)
    show_help
    exit 0
    ;;
  d)
    DOWNLOAD=1
    ;;
  c)
    CONFIGURE=1
    ;;
  C)
    COMPILE=1
    ;;
  esac
done

#-------------------------------------------------------#
#                                                       #
#                  Download sources                     #
#                                                       #
#-------------------------------------------------------#

if [ $DOWNLOAD == "1" ]; then
  printf "\e[92mDownloading rt-app\e[0m --->  "
  git clone https://github.com/gbagnoli/rt-app.git > /dev/null 2>&1 &
  spin $!

  printf "\e[92mDownloading kernel sources (this may take a while)\e[0m --->  "
  git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git > /dev/null 2>&1 &
  spin $!
  
  printf "\e[92mDownloading schedtool-dl\e[0m --->  "
  git clone https://github.com/jlelli/schedtool-dl.git > /dev/null 2>&1 &
  spin $!
  
  printf "\e[92mDownloading xfce4-taskmanager-dl\e[0m --->  "
  git clone https://github.com/alessandrelli/xfce4-taskmanager-dl.git > /dev/null 2>&1 &
  spin $!
fi

#-------------------------------------------------------#
#                                                       #
#                      Configure                        #
#                                                       #
#-------------------------------------------------------#

if [ $CONFIGURE == "1" ]; then
  printf "\e[92mConfiguring rt-app\e[0m [1] --->  "
  if [ ! -d "rt-app" ]; then
     printf "\n\e[91mERROR: \e[0mrt-app sources not found!\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -d option\n"
     exit 1
  fi
  cd rt-app
  ./autogen.sh > /dev/null 2>&1 &
  spin $!
  printf "                   [2] --->  "
  ./configure --with-deadline --with-json > /dev/null 2>&1 &
  spin $!
  cd ..

  printf "\e[92mConfiguring kernel sources\e[0m [1] --->  "
  if [ ! -d "linux" ]; then
     printf "\n\e[91mERROR: \e[0mkernel sources not found!\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -d option\n"
     exit 1
  fi
  cd linux
  make mrproper > /dev/null 2>&1 &
  spin $!
  wget http://retis.sssup.it/~jlelli/kernels/config_kvm > /dev/null 2>&1
  if [ $? != "0" ]; then
    printf "\n\e[33mERROR: \e[0mkvm custom kernel config download failed...\n"
    printf "\e[92mretrying with current kernel config\e[0m\n"
    cp /boot/config-`uname -r` .config
  else
    mv config_kvm .config
  fi
  scripts/config --disable CONFIG_NO_HZ --set-val CONFIG_HZ 1000\
  --enable CONFIG_HZ_1000 --disable CONFIG_HZ_250 --enable CONFIG_HZ_1000\
  --enable CONFIG_PREEMPT --disable CONFIG_PREEMPT_VOLUNTARY
  printf "                           [2] --->  "
  yes "" | make oldconfig > /dev/null 2>&1 &
  spin $!
  cd ..

  printf "\e[92mConfiguring xfce4-taskmanager-dl\e[0m --->  "
  if [ ! -d "xfce4-taskmanager-dl" ]; then
     printf "\n\e[91mERROR: \e[0mxfce4-taskmanager-dl sources not found!\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -d option\n"
     exit 1
  fi
  cd xfce4-taskmanager-dl
  ./autogen.sh > /dev/null 2>&1 &
  spin $!
  cd ..

fi

#-------------------------------------------------------#
#                                                       #
#                       Compile                         #
#                                                       #
#-------------------------------------------------------#

if [ $COMPILE == "1" ]; then
  printf "\e[92mCompiling rt-app\e[0m --->  "
  if [ ! -d "rt-app" ]; then
     printf "\n\e[91mERROR: \e[0mrt-app sources not found!\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -d option\n"
     exit 1
  fi
  cd rt-app
  make > compile.log 2>&1 &
  spin $!
  if [ $? != "0" ]; then
     printf "\n\e[91mERROR: \e[0mcompilation failed! (see rt-app/compile.log for details)\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -c option\n"
     cd ..
     exit 1
  fi 
  cd ..

  printf "\e[92mCompiling kernel sources (this may take a while)\e[0m --->  "
  if [ ! -d "linux" ]; then
     printf "\n\e[91mERROR: \e[0mkernel sources not found!\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -d option\n"
     exit 1
  fi
  cd linux
  make -j`cat /proc/cpuinfo | grep processor | wc -l | awk '{print $1 + 1}'` bzImage\
  > compile.log 2>&1 &
  spin $!
  if [ $? != "0" ]; then
     printf "\n\e[91mERROR: \e[0mcompilation failed! (see linux/compile.log for details)\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -c option\n"
     cd ..
     exit 1
  fi 
  cd ..

  printf "\e[92mCompiling schedtool-dl\e[0m --->  "
  if [ ! -d "schedtool-dl" ]; then
     printf "\n\e[91mERROR: \e[0mschedtool-dl sources not found!\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -d option\n"
     exit 1
  fi
  cd schedtool-dl
  make > compile.log 2>&1 &
  spin $!
  if [ $? != "0" ]; then
     printf "\e[91mERROR: \e[0mcompilation failed! (see schedtool-dl/compile.log for details)\n"
     cd ..
     exit 1
  fi 
  cd ..

  printf "\e[92mCompiling xfce4-taskmanager-dl\e[0m --->  "
  if [ ! -d "xfce4-taskmanager-dl" ]; then
     printf "\n\e[91mERROR: \e[0mxfce4-taskmanager-dl sources not found!\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -d option\n"
     exit 1
  fi
  cd xfce4-taskmanager-dl
  make > compile.log 2>&1 &
  spin $!
  if [ $? != "0" ]; then
     printf "\n\e[91mERROR: \e[0mcompilation failed! (see xfce4-taskmanager-dl/compile.log for details)\n"
     printf "\e[33mHINT: \e[0mtry to run this script with -c option\n"
     cd ..
     exit 1
  fi 
  cd ..
fi
