#!/bin/bash

rois=`jq -r '.rois' config.json`
roi1=`jq -r '.seed_roi' config.json`

fslmaths varea_whole.nii.gz -bin varea_bin.nii.gz

ROI1=$rois/ROI${roi1}.nii.gz
if [[ ${roi1} == 008109 ]]; then
        # make left hemisphere eccentricity
        fslmaths varea_bin.nii.gz -mul lh.ribbon.nii.gz varea.nii.gz
else
        # make right hemisphere eccentricity
        fslmaths varea_bin.nii.gz -mul rh.ribbon.nii.gz varea.nii.gz
fi

