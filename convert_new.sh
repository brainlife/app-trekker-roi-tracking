#!/bin/bash

## Create white matter mask and move rois to diffusion space for tracking

#exit if any command fails
#set -e 

#show commands runnings
#set -x

input_nii_gz=$(jq -r .dwi config.json)
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
dtiinit=`jq -r '.dtiinit' config.json`
fsurfer=`jq -r '.freesurfer' config.json`
eccentricity=`jq -r '.eccentricity' config.json`
hemi="lh rh"

if [[ ! ${dtiinit} == "null" ]]; then
        export input_nii_gz=$dtiinit/`jq -r '.files.alignedDwRaw' $dtiinit/dt6.json`
fi

for HEMI in $hemi
do
        mri_vol2vol --mov $fsurfer/mri/${HEMI}.ribbon.mgz --targ ${input_nii_gz} --regheader --o ${HEMI}.ribbon.nii.gz
done

mri_vol2vol --mov ${fsurfer}/mri/ribbon.mgz --targ ${input_nii_gz} --regheader --o ribbon.nii.gz

mri_vol2vol --mov ${fsurfer}/mri/aparc.a2009s+aseg.mgz --targ ${input_nii_gz} --regheader --o aparc.a2009s.aseg.nii.gz

mri_vol2vol --mov ${eccentricity} --targ ${input_nii_gz} --regheader --o eccentricity.nii.gz
