#!/bin/bash

set -x
#set -e

input_nii_gz=$(jq -r .dwi config.json) # will use dwi if inputted
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
dtiinit=`jq -r '.dtiinit' config.json` # will use dtiinit if inputted
fsurfer=`jq -r '.freesurfer' config.json` # freesurfer for the aparc aseg
prfDir=`jq -r '.prf' config.json`
prfSurfacesDir=${prfDir}/prf_surfaces
seedROI=`jq -r '.seed_roi' config.json`
minDegree=(`jq -r '.MinDegree' config.json`) # min degree for binning of eccentricity
maxDegree=(`jq -r '.MaxDegree' config.json`) # max degree for binning of eccentricity
freesurfer=`jq -r '.freesurfer' config.json`

# this will set dtiinit as the input dwi nifti if dtiinit is selected
if [[ ! ${dtiinit} == "null" ]]; then
        export input_nii_gz=$dtiinit/`jq -r '.files.alignedDwRaw' $dtiinit/dt6.json`
fi

# set hemisphere
if [[ ${seedROI} == '008109' ]]; then # left hemisphere
	hemi="lh"
else
	hemi="rh"
fi

# move freesurfer hemisphere ribbon into diffusion space
mri_vol2vol --mov $freesurfer/mri/${hemi}.ribbon.mgz --targ ${input_nii_gz} --regheader --o ${hemi}.ribbon.nii.gz

# move freesurfer whole-brain ribbon into diffusion space
mri_vol2vol --mov ${freesurfer}/mri/ribbon.mgz --targ ${input_nii_gz} --regheader --o ribbon.nii.gz

# move aparc aseg in diffusion space
mri_label2vol --seg ${freesurfer}/mri/aparc.a2009s+aseg.mgz --temp ${input_nii_gz} --regheader --o aparc.a2009s.aseg.nii.gz

# convert surface to gifti
mris_convert -c ${prfSurfacesDir}/${hemi}.eccentricity ${freesurfer}/surf/${hemi}.pial ${hemi}.eccentricity.func.gii
mris_convert -c ${prfSurfacesDir}/${hemi}.varea ${freesurfer}/surf/${hemi}.pial ${hemi}.varea.func.gii

# create v1 surface
mri_binarize --i ./${hemi}.varea.func.gii --match 1 --o ./${hemi}.varea.v1.func.gii

# create eccentricity surface
for DEG in ${!minDegree[@]}; do
	# genereate eccentricity bin sufaces
	mri_binarize --i ./${hemi}.eccentricity.func.gii --min ${minDegree[$DEG]} --max ${maxDegree[$DEG]} --o ./${hemi}.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.func.gii

	# multiply eccentricities by v1
	wb_command -metric-math 'x*y' ${hemi}.v1.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.func.gii -var x ${hemi}.varea.v1.func.gii -var y ${hemi}.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.func.gii

	# map surface to volume
	SUBJECTS_DIR=${freesurfer}
	mri_surf2vol --o ./Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz --subject ./ --so ${freesurfer}/surf/${hemi}.pial ./${hemi}.v1.Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.func.gii

	mri_vol2vol --mov Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz --targ ${input_nii_gz} --regheader --o Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.nii.gz --nearest
done
