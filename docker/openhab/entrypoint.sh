#!/bin/sh

SOURCE=/opt/openhab/addons-available
DEST=/opt/openhab/addons

IFS=","
for addon in $ADDONS
do
  if [ -f $SOURCE/$addon-*.jar ]
  then
    ln -s $SOURCE/$addon-*.jar $DEST/
  else
    echo $addon not found
  fi
done

rm -rf /opt/openhab/configurations
ln -s /etc/openhab/configurations /opt/openhab
/opt/openhab/start.sh
