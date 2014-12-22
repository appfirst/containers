#!/bin/bash

IMAGE_NAME="appfirst_image"
TID="1"
BASE_IMAGE="ubuntu:latest"
SUPERVISORD_CFG_PATH="/etc/supervisor/conf.d"
SUPERVISORD_CFG_LIST="appfirst.conf;"
DOCKER_FILE_PATH="."
DOCKER_FILE_NAME="Dockerfile"
MAINTAINER="AppFirst Dev <dev@appfirst.com>"
VERSION="0.0.1"
ARCH="x86_64"
APPFIRST_PACKAGE=""
DOWNLOAD_AND_INSTALL_CMD=""
INSTALL_SUPERVISOR_CMD=""

function help_info()
{
    echo "$0"
    echo -e "\t--name=<value>\t\t\t - image name"
    echo -e "\t--arch=<value>\t\t\t - AppFirst package architecture"
    echo -e "\t--base_image=<value>\t\t - base image"
    echo -e "\t--docker_file_path=<value>\t - Dockerfile path"
    echo -e "\t--tid=<value>\t\t\t - tenant ID"
    echo -e "\t--supervisord_cfg_path=<value>\t - supevisord config files path"
    echo -e "\t--supervisord_cfg=<value>\t - list of supevisord config files"
    exit
}

for i in "$@"
do
  case $i in
  --arch=*)
    ARCH=${i#*=}
    ;;  
  --name=*)
    IMAGE_NAME=${i#*=}
    ;;
  --base_image=*)
    BASE_IMAGE=${i#*=}
    ;;
  --docker_file_path=*)
    DOCKER_FILE_PATH=${i#*=}
    ;;
  --tid*)
    TID=${i#*=}
    ;;
  --supervisord_cfg_path=*)
    SUPERVISORD_CFG_PATH=${i#*=}
    ;;
  --supervisord_cfg=*)
    SUPERVISORD_CFG_LIST=$SUPERVISORD_CFG_LIST${i#*=}
    ;;
  ?|/?|--help)
    help_info
    ;;
  esac
done

case "$BASE_IMAGE" in 
  *centos*)
    APPFIRST_PACKAGE="appfirst-"$ARCH."rpm"
    DOWNLOAD_AND_INSTALL_CMD="sudo rpm -ihv http://wwws.appfirst.com/packages/initial/$TID/$APPFIRST_PACKAGE"
    INSTALL_SUPERVISOR_CMD="yum install python-setuptools && easy_install pip && pip install supervisor"
    ;;
  *ubuntu*)
    APPFIRST_PACKAGE="appfirst-"$ARCH."deb"
    DOWNLOAD_AND_INSTALL_CMD="wget http://wwws.appfirst.com/packages/initial/$TID/$APPFIRST_PACKAGE && dpkg -i $APPFIRST_PACKAGE && rm $APPFIRST_PACKAGE"
    INSTALL_SUPERVISOR_CMD="apt-get update && apt-get install -y supervisor wget"
    ;;
esac

# Docker file name
DOCKER_FILE=$DOCKER_FILE_PATH/$DOCKER_FILE_NAME

#build info
echo -e "\tImage name:\t\t\t\t" $IMAGE_NAME
echo -e "\tBase image:\t\t\t\t" $BASE_IMAGE
echo -e "\tDocker file name:\t\t\t" $DOCKER_FILE
echo -e "\tTenant ID:\t\t\t\t" $TID
echo -e "\tSupervisord config files path:\t\t" $SUPERVISORD_CFG_PATH
echo -e "\tSupervisord config files:\t\t" $SUPERVISORD_CFG_LIST
echo -e "\tAppFirst package name:\t\t\t" $APPFIRST_PACKAGE

#generate Dockerfile header
echo -e "# AppFirst Collector"      >  $DOCKER_FILE
echo -e "#"                         >> $DOCKER_FILE
echo -e "# VERSION\t"$VERSION       >> $DOCKER_FILE
echo -e ""                          >> $DOCKER_FILE
echo -e "FROM\t\t"$BASE_IMAGE       >> $DOCKER_FILE
echo -e "MAINTAINER\t"$MAINTAINER   >> $DOCKER_FILE
echo -e ""                          >> $DOCKER_FILE

#install wget and supervisord
echo -e "RUN $INSTALL_SUPERVISOR_CMD"   >> $DOCKER_FILE
#download and install the collector package
echo -e "RUN $DOWNLOAD_AND_INSTALL_CMD" >> $DOCKER_FILE

#set enviroment variables
echo -e ""                                                      >> $DOCKER_FILE
#echo -e "ENV LD_LIBRARY_PATH /usr/share/appfirst"               >> $DOCKER_FILE
#echo -e "ENV LD_PRELOAD /usr/share/appfirst/libwrap.so.1.0.1"   >> $DOCKER_FILE

#parse supervisord config list
echo -e ""                          >> $DOCKER_FILE
OLD_IFS="$IFS"
IFS=";" read -ra CFG_ARRAY <<< "$SUPERVISORD_CFG_LIST"
IFS="$OLD_IFS"
for f in "${CFG_ARRAY[@]}"
do
  echo "COPY $f $SUPERVISORD_CFG_PATH/$f" >> $DOCKER_FILE
done

echo "COPY startup.sh /startup.sh" >> $DOCKER_FILE

#start supervisord
#echo -e ""                              >> $DOCKER_FILE
#echo "CMD [\"/usr/bin/supervisord\"]"   >> $DOCKER_FILE

#docker build -t $IMAGE_NAME .