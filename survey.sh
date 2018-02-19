startTime=$(date +%s)
camerasRoot="/cameras"
find $camerasRoot -name "*.tmp" -exec rm {} \;
if [ ! -f /cameras/index.html ]; then
  cp /index.html cameras/index.html
fi
while true; do
  source /conf/cameras.conf
  json="{\"cameras\": ["
  cams=""
  for camera in $cameras; do
    name="${camera}_name"; name=${!name:-$camera}
    url="${camera}_url"; url=${!url}
    user="${camera}_user"; user=${!user}
    password="${camera}_password"; password=${!password}
    conversionInterval="${camera}_conversionInterval"; conversionInterval=${!conversionInterval:-3600}
    echo "$camera ($name) / $url"
    annotation="${camera}_annotation"; annotation=${!annotation:-"$name %Y-%m-%d\ %H:%M:%S\ \(%Z\)"}
    if [ -n "$cams" ]; then
      cams=${cams}","
    fi
    cams=${cams}"{"
    cams=${cams}"\"camera\":\"${camera}\""
    cams=${cams}", "
    cams=${cams}"\"name\":\"${name}\""
    cams=${cams}", "
    cams=${cams}"\"latestImage\":\"${camera}.jpg\""
    cams=${cams}"}"

    prefix=$camerasRoot/${camera}
    if [ ! -d $prefix ]; then
      mkdir -p $prefix
    fi
    echo Prefix: $prefix
    d=$(date +%Y.%m.%d-%H:%M:%S)
    #echo "Date: $d"
    date=$(date --date="$d" +%Y-%m-%d-%H-%M-%S)
    annotation=$(eval echo "$annotation")
    filename=$prefix/$date.jpg
    tmpfilename=$filename.tmp
    ( ((/usr/bin/wget $url -O $tmpfilename --user=$user --password=$password || (echo "Could not get camera image"; rm "$tmpfilename"; false)) && \
     imgDate=`date --date="$d" +"$annotation"` && \
     convert "$tmpfilename" -gravity NorthWest -pointsize 22 -fill white -annotate +30+30 "$imgDate" "$tmpfilename") && mv $tmpfilename $filename && (cd $camerasRoot; ln -sf ${camera}/${date}.jpg ${camera}.jpg) ) &
    lastConversion="${camera}_lastConversion"; lastConversion=${!lastConversion:-$startTime}
    if [ $(expr $(date +%s) - $lastConversion) -gt $conversionInterval ]; then
      echo Triggering converson
      (./convert.sh $prefix *.jpg $prefix) &
      eval ${camera}_lastConversion=$(date +%s)
    fi
  done
  json=${json}${cams}"]}"
  echo $json > $camerasRoot/index.json.new && mv $camerasRoot/index.json.new $camerasRoot/index.json
  sleep 1
done
