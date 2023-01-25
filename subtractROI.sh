#!/bin/bash

# subtract seed and termination ROIs from exclusion ROI (if provided)
exclusion=`jq -r '.exclusion' config.json`

if [[ -z ${exclusion} ]]; then
    echo "no exclusion ROIs inputted. skipping"
    exit
fi

# set -ex

# set exclusion roi entries to be easier to index
exclusion=(${exclusion})

# check to see if reslicing was done. if not, copy over ROIs to resliced_rois folder to make things simpler
if [ ! -d ./resliced_rois ]; then
    mkdir resliced_rois
    rois=`jq -r '.rois' config.json`
    cp -R ${rois}/* ./resliced_rois
fi
rois="./resliced_rois"

# grab roi pairs from config and identify number of tracts
roiPair=`jq -r '.roiPair' config.json`
pairs=($roiPair)
range=` expr ${#pairs[@]}`
nTracts=` expr ${range} / 2`

# loop through number of tracts and subtract seed and termination ROIs for that tract with the exclusion mask for that tract
for (( i=0; i<${nTracts}; i++ ));
do
    seed=$rois/*${pairs[$((i*2))]}.nii.gz
    term=$rois/*${pairs[$((i*2+1))]}.nii.gz
    exclu=$rois/*${exclusion[$((i))]}.nii.gz
    fslmaths $exclu -sub $seed -sub $term -thr 0 -bin $exclu
done