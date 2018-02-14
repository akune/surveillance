#!/bin/bash

originalDir=$(pwd)
dateString=$(date +%Y-%m-%d-%H-%M-%S)

imageDir=${1:-"$HOME/surveillance/camera01"}
imagePattern=${2:-"*.jpg"}
outputDir=${3-$(pwd)}
outputPrefix=${4:-""}

echo Source: $imageDir
echo Target: $outputDir

tmpDir=$(mktemp -d)
echo "Working in $tmpDir"
cd $imageDir
#i=0; for file in $(ls -tr1 $imagePattern); do mv $file $tmpDir/photo$i.jpg; i=$((i+1)); done
mv $imageDir/$imagePattern $tmpDir
#i=0; for file in $(ls -tr1 $imagePattern); do cp -a $file $tmpDir/photo$i.jpg; i=$((i+1)); done
#cd $tmpDir
convert="ffmpeg -framerate 60 -pattern_type glob -i '$tmpDir/*.jpg' -crf 25 -pix_fmt yuv420p $outputDir/$outputPrefix$dateString.mp4"
echo $convert
(eval $convert && (echo "Done converting" && echo "Cleaning up" && rm -R $tmpDir) || echo "Converting failed")
echo "Done"
