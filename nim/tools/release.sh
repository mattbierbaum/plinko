#!/bin/sh

DIRS=/tmp/files.txt

nim release
echo "build\njson\nscripts\ntools" > ${DIRS}
tar cvf release.tar.gz -T ${DIRS}
