#!/bin/bash

rm ~/ab/*

docker run -it --rm -v ~/ab:/mnt/jmg \
ab 1000 500

mydir=$PWD
cd ~/ab && ls *.dat > ${mydir}/zips.txt

cd $mydir

while IFS= read -r line
do
echo $line
docker run -d --rm -v ~/ab:/mnt/jmg \
func az storage blob upload --file /mnt/jmg/${line} \
--name ${line} --container-name ab-test
done < "./zips.txt"