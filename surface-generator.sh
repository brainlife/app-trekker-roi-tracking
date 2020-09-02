#!/bin/bash

# output lines to log files and fail if error
set -x
set -e

# parse inputs
prfSurfacesDir=`jq -r '.prfSurfacesDir' config.json`
minDegree=`jq -r '.min_degree' config.json` # min degree for binning of eccentricity
maxDegree=`jq -r '.max_degree' config.json` # max degree for binning of eccentricity
freesurfer=`jq -r '.freesurfer' config.json`
hemispheres=`jq -r '.hemispheres' config.json`

# make degrees loopable
minDegree=($minDegree)
maxDegree=($maxDegree)

# set dwi as input
input_nii_gz="dwi.nii.gz"

# move freesurfer whole-brain ribbon into diffusion space
[ ! -f ribbon.nii.gz ] && mri_vol2vol --mov ${freesurfer}/mri/ribbon.mgz --targ ${input_nii_gz} --regheader --o ribbon.nii.gz

# move aparc aseg in diffusion space
[ ! -f aparc.a2009s.aseg.nii.gz ] && mri_label2vol --seg ${freesurfer}/mri/aparc.a2009s+aseg.mgz --temp ${input_nii_gz} --regheader --o aparc.a2009s.aseg.nii.gz

# loop through hemispheres
for hemi in ${hemispheres}
do
	# move freesurfer hemisphere ribbon into diffusion space
	[ ! -f ${hemi}.ribbon.nii.gz ] && mri_vol2vol --mov $freesurfer/mri/${hemi}.ribbon.mgz --targ ${input_nii_gz} --regheader --o ${hemi}.ribbon.nii.gz

	# convert surface to gifti
	[ ! -f ${hemi}.eccentricity.func.gii ] && mris_convert -c ${prfSurfacesDir}/${hemi}.eccentricity ${freesurfer}/surf/${hemi}.pial ${hemi}.eccentricity.func.gii
	[ ! -f ${hemi}.varea.func.gii ] && mris_convert -c ${prfSurfacesDir}/${hemi}.varea ${freesurfer}/surf/${hemi}.pial ${hemi}.varea.func.gii

	# create v2 surface
	[ ! -f ${hemi}.varea.v2.func.gii ] && mri_binarize --i ./${hemi}.varea.func.gii --match 2 --o ./${hemi}.varea.v2.func.gii

	# create eccentricity surface
	for DEG in ${!minDegree[@]}; do
		# genereate eccentricity bin surfaces and multiply eccentricities by v2
		[ ! -f ${hemi}.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.func.gii ] && mri_binarize --i ./${hemi}.eccentricity.func.gii --min ${minDegree[$DEG]} --max ${maxDegree[$DEG]} --o ./${hemi}.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.func.gii && wb_command -metric-math 'x*y' ${hemi}.v2.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.func.gii -var x ${hemi}.varea.v2.func.gii -var y ${hemi}.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.func.gii

		# map surface to volume
		SUBJECTS_DIR=${freesurfer}
		[ ! -f ${hemi}.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz ] && mri_surf2vol --o ./${hemi}.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz --subject ./ --so ${freesurfer}/surf/${hemi}.pial ./${hemi}.v2.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.func.gii && mri_vol2vol --mov ${hemi}.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz --targ ${input_nii_gz} --regheader --o ${hemi}.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz --nearest
	done
done
