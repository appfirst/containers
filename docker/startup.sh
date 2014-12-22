#!/bin/bash

SUPERVISORD_CFG_PATH="/etc/supervisor/conf.d"
CUSTOM_CMD_CFG_FILE=$SUPERVISORD_CFG_PATH/"custom.conf"
CMD_ENV=""
CMD_PRIORITY=1

for i in "$@"
do
  case $i in
    --tid*)
      TID=${i#*=}
      sed -i "/Tenant/c\   Tenant $TID" /etc/AppFirst
      ;;
    --custom-cmd*)
      CUSTOM_CMD=${i#*=}
      ;;
    --cmd-env*)
      CMD_ENV=${i#*=}
      ;;
    --cmd-priority*)
      CMD_PRIORITY=${i#*=}
      ;;
  esac
done

if [ -n "$CUSTOM_CMD" ]; then
  echo -e "[supervisord]" > $CUSTOM_CMD_CFG_FILE
  echo -e "nodaemon=true" >> $CUSTOM_CMD_CFG_FILE
  echo -e "" >> $CUSTOM_CMD_CFG_FILE
  echo -e "[program:custom_cmd]" >> $CUSTOM_CMD_CFG_FILE
  echo -e "command=$CUSTOM_CMD" >> $CUSTOM_CMD_CFG_FILE
  echo -e "priority=$CMD_PRIORITY" >> $CUSTOM_CMD_CFG_FILE
  if [ -n "$CMD_ENV" ]; then
    echo -e "environment=$CMD_ENV" >> $CUSTOM_CMD_CFG_FILE
  fi
fi

#check LD_PRELOAD
if [ -f /etc/ld_preload ]; then
  if [ -s /etc/ld.so.preload ]; then
    exec < /etc/ld.so.preload
    value=0
    while read value
      do
        grep $value /etc/ld_preload > /dev/null
        if [ $? -ne 0 ]; then
          cat $value >> /etc/ld_preload
        fi
    done
  fi

  if [ -e /dev/shm ]; then
    /bin/cp -f /etc/ld_preload /dev/shm/.
    /bin/ln -fs /dev/shm/ld_preload /etc/ld.so.preload  
  else
    /bin/cp -f /etc/ld_preload /tmp/.
    /bin/ln -fs /tmp/ld_preload /etc/ld.so.preload  
  fi
else 
  /bin/rm -f /etc/ld.so.preload
fi

#run supervisord
supervisord -n