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
varea=`jq -r '.varea' config.json`
hemi="lh rh"

if [[ ! ${dtiinit} == "null" ]]; then
        export input_nii_gz=$dtiinit/`jq -r '.files.alignedDwRaw' $dtiinit/dt6.json`
fi

for HEMI in $hemi
do
        mri_label2vol --seg $fsurfer/mri/${HEMI}.ribbon.mgz --temp ${input_nii_gz} --regheader $fsurfer/mri/${HEMI}.ribbon.mgz --o ${HEMI}.ribbon.nii.gz
done
