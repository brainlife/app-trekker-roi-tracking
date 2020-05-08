#!/bin/bash

#reslice ROIS to make it the same size as the input dwi
reslice=`jq -r '.reslice' config.json`
if [ $reslice != "true" ]; then
    echo "Requested not to reslice rois - dimensions must match the dwi or some process will fail"
    exit
fi

set -e
set -x

DIFF=$1
rois=`jq -r '.rois' config.json`

#export SUBJECTS_DIR=`pwd`
mkdir -p resliced_rois
for ROI in $(ls $rois/*.nii.gz); do
    output=resliced_rois/$(basename $ROI)
    if [ ! -f $output ]; then
	mri_vol2vol --targ $DIFF --mov $ROI --regheader --o $output
    fi
done
