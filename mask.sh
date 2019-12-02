#!/bin/bash

rois=`jq -r '.rois' config.json`
roi1=`jq -r '.seed_roi' config.json`
roi2=`jq -r '.term_roi' config.json`

ROI2=$rois/ROI${roi2}.nii.gz

fslmaths ${ROI2} -bin v1_bin.nii.gz
if [ ${roi1} == 008109 ]; then
	fslmaths v1_bin.nii.gz -mul lh.ribbon.nii.gz v1.nii.gz
else
	fslmaths v1_bin.nii.gz -mul rh.ribbon.nii.gz v1.nii.gz
fi
