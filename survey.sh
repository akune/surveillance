startTime=$(date +%s)
while true; do
  source /conf/cameras.conf
  for camera in $cameras; do
    name="${camera}_name"; name=${!name:-$camera}
    url="${camera}_url"; url=${!url}
    user="${camera}_user"; user=${!user}
    password="${camera}_password"; password=${!password}
    conversionInterval="${camera}_conversionInterval"; conversionInterval=${!conversionInterval:-3600}
    echo "$camera ($name) / $url"

    prefix=/cameras/${camera}
    if [ ! -d $prefix ]; then
      mkdir -p $prefix
    fi
    echo Prefix: $prefix
    d=$(date +%Y.%m.%d-%H:%M:%S)
    #echo "Date: $d"
    date=$(date --date="$d" +%Y-%m-%d-%H-%M-%S)
    filename=$prefix/$date.jpg
    tmpfilename=$filename.tmp
    ( (/usr/bin/wget $url -O $tmpfilename --user=$user --password=$password && \
     imgDate=`date --date="$d" +%Y-%m-%d\ %H:%M:%S\ \(%Z\)` && \
     convert "$tmpfilename" -gravity NorthWest -pointsize 22 -fill white -annotate +30+30 "$imgDate" "$tmpfilename") && mv $tmpfilename $filename && (cd /cameras; ln -sf ${camera}/${date}.jpg ${camera}.jpg) ) &
    lastConversion="${camera}_lastConversion"; lastConversion=${!lastConversion:-$startTime}
    if [ $(expr $(date +%s) - $lastConversion) -gt $conversionInterval ]; then
      echo Triggering converson
      (./convert.sh $prefix *.jpg $prefix) &
      eval ${camera}_lastConversion=$(date +%s)
    fi
  done
  sleep 1
done
