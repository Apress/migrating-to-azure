#!/bin/bash
timestamp(){
    date "+%Y-%m-%d %H:%M:%S"
}

getrunid() {
    python -c 'import uuid; print str(uuid.uuid4())'
}

echo "${2} concurrent connections requested"
echo  "${1} requests requested"
i=0
rm /mnt/jmg/links.txt
touch /mnt/jmg/links.txt

runtime=`timestamp`
runid=`getrunid`

while IFS= read -r line
do
    ((i++))
    ab -n $1 -c $2 -r -g "/mnt/jmg/out${i}.dat" $line
    echo "${line},out${i}.dat,${runid},${runtime}" >> /mnt/jmg/links.txt
done < "./Urls.txt"

cd /mnt/jmg

echo ${runid}
echo ${runtime}

zip "${runid}.zip" o*.dat
zip "${runid}.zip" links.txt


