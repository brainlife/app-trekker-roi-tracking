#!/bin/bash

dwi=$(jq -r .dwi config.json)
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
dtiinit=`jq -r '.dtiinit' config.json`
freesurfer=`jq -r '.freesurfer' config.json`
varea=`jq -r '.varea' config.json`
hemi="lh rh"

if [[ ! ${dtiinit} == "null" ]]; then
        dwi=$dtiinit/*dwi_aligned*.nii.gz
        bvals=$dtiinit/*.bvals
        bvecs=$dtiinit/*.bvecs
fi

for HEMI in $hemi
do
	mri_label2vol --seg $freesurfer/mri/${HEMI}.ribbon.mgz --temp ${dwi} --regheader $freesurfer/mri/${HEMI}.ribbon.mgz --o ${HEMI}.ribbon.nii.gz
done

mri_label2vol --seg ${varea} --temp ${dwi} --regheader ${varea} --o varea_whole.nii.gz
