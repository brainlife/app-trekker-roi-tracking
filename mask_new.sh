#!/bin/bash

rois=`jq -r '.rois' config.json`
roi1=`jq -r '.seed_roi' config.json`
roi2=`jq -r '.term_roi' config.json`
minDegree=(`jq -r '.MinDegree' config.json`)
maxDegree=(`jq -r '.MaxDegree' config.json`)

if [[ ${roi1} == '008109' ]]; then
	# make left hemisphere eccentricity
	fslmaths ribbon.nii.gz -thr 40 -bin ribbon_right.nii.gz
	fslmaths $rois/ROI${roi2}.nii.gz -mul lh.ribbon.nii.gz v1.nii.gz
	fslmaths eccentricity.nii.gz -mul lh.ribbon.nii.gz eccentricity_left.nii.gz
	for DEG in ${!minDegree[@]}
	do
		fslmaths eccentricity_left.nii.gz -thr ${minDegree[$DEG]} -uthr ${maxDegree[$DEG]} -bin Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz
	done
else
	# make right hemisphere eccentricity
	fslmaths ribbon.nii.gz -uthr 10 -bin ribbon_left.nii.gz
	fslmaths $rois/ROI${roi2}.nii.gz -mul rh.ribbon.nii.gz v1.nii.gz
	fslmaths eccentricity.nii.gz -mul rh.ribbon.nii.gz eccentricity_right.nii.gz
	for DEG in ${!minDegree[@]}
	do
		fslmaths eccentricity_right.nii.gz -thr ${minDegree[$DEG]} -uthr ${maxDegree[$DEG]} -bin Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz
	done
fi

