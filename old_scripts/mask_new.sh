#!/bin/bash

rois=`jq -r '.rois' config.json` # roi directory
roi1=`jq -r '.seed_roi' config.json` # seed roi (i.e. left or right lgn)
roi2=`jq -r '.term_roi' config.json` # term roi (i.e. v1)
minDegree=(`jq -r '.MinDegree' config.json`) # min degree for binning of eccentricity
maxDegree=(`jq -r '.MaxDegree' config.json`) # max degree for binning of eccentricity

# generate appropriate hemispheric ROIs for tracking, including binning eccentricity map and smoothing with a gaussian kernel
if [[ ${roi1} == '008109' ]]; then # left hemisphere
	# make left hemisphere eccentricity
	fslmaths ribbon.nii.gz -thr 40 -bin ribbon_right.nii.gz # can be used as exclusion mask for streamlines going cross hemisphere
	fslmaths $rois/ROI${roi2}.nii.gz -mul lh.ribbon.nii.gz -bin v1.nii.gz # generating left hemisphere v1
	fslmaths eccentricity.nii.gz -mul lh.ribbon.nii.gz eccentricity_left.nii.gz # generating left hemisphere eccentricity
	fslmaths eccentricity_left.nii.gz -mul v1.nii.gz eccentricity_left_v1.nii.gz # multiplying left hemisphere eccentricity by v1 to generate v1 eccentricity
	# generate binned eccentricity rois and smooth
	for DEG in ${!minDegree[@]}
	do
		# binned eccentricity roi generation
		fslmaths eccentricity_left_v1.nii.gz -thr ${minDegree[$DEG]} -uthr ${maxDegree[$DEG]} -bin Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz

		# smooth with gaussian smoothing kernel
		fslmaths Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz -kernel gauss 3 -fmean Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}_smooth.nii.gz

		# threshold and binarize smoothed eccentricity rois
		fslmaths Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}_smooth.nii.gz -thr .1 -bin Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}_smooth_thresh_bin.nii.gz
	done
else
	# make right hemisphere eccentricity
	fslmaths ribbon.nii.gz -uthr 10 -bin ribbon_left.nii.gz # can be used as exclusion mask for streamlines crossing hemisphere
	fslmaths $rois/ROI${roi2}.nii.gz -mul rh.ribbon.nii.gz -bin v1.nii.gz # generate right hemisphere v1
	fslmaths eccentricity.nii.gz -mul rh.ribbon.nii.gz eccentricity_right.nii.gz # generate right hemisphere eccentricity
	fslmaths eccentricity_right.nii.gz -mul v1.nii.gz eccentricity_right_v1.nii.gz
	# generate binned eccentricity rois and smooth with gaussian smoothing kernel
	for DEG in ${!minDegree[@]}
	do
		# generate binned eccentricity rois
		fslmaths eccentricity_right_v1.nii.gz -thr ${minDegree[$DEG]} -uthr ${maxDegree[$DEG]} -bin Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz

		# smooth with gaussian smoothing kernel
		fslmaths Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz -kernel gauss 3 -fmean Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}_smooth.nii.gz

		# threshold and binarize
		fslmaths Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}_smooth.nii.gz -thr .1 -bin Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}_smooth_thresh_bin.nii.gz
	done
fi

