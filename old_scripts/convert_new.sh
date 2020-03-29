#!/bin/bash

## Create white matter mask and move rois to diffusion space for tracking

#exit if any command fails
#set -e 

#show commands runnings
set -x

input_nii_gz=$(jq -r .dwi config.json) # will use dwi if inputted
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
dtiinit=`jq -r '.dtiinit' config.json` # will use dtiinit if inputted
fsurfer=`jq -r '.freesurfer' config.json` # freesurfer for the aparc aseg
eccentricity=`jq -r '.eccentricity' config.json` #  eccentricity map from prf
hemi="lh rh"

# this will set dtiinit as the input dwi nifti if dtiinit is selected
if [[ ! ${dtiinit} == "null" ]]; then
        export input_nii_gz=$dtiinit/`jq -r '.files.alignedDwRaw' $dtiinit/dt6.json`
fi

# move freesurfer hemisphere ribbons into diffusion space
for HEMI in $hemi
do
        mri_vol2vol --mov $fsurfer/mri/${HEMI}.ribbon.mgz --targ ${input_nii_gz} --regheader --o ${HEMI}.ribbon.nii.gz
done

# move freesphere whole brain ribbon into diffusion space
mri_vol2vol --mov ${fsurfer}/mri/ribbon.mgz --targ ${input_nii_gz} --regheader --o ribbon.nii.gz

# move aparc aseg into diffusion space
mri_vol2vol --mov ${fsurfer}/mri/aparc.a2009s+aseg.mgz --targ ${input_nii_gz} --regheader --o aparc.a2009s.aseg.nii.gz

# move eccentricity map to diffusion space
#mri_vol2vol --mov ${eccentricity} --targ ${input_nii_gz} --regheader --o eccentricity.nii.gz
