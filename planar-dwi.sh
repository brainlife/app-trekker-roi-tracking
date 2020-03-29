#!/bin/bash

input_nii_gz=$(jq -r .dwi config.json) # will use dwi if inputted
dtiinit=`jq -r '.dtiinit' config.json` # will use dtiinit if inputted

# this will set dtiinit as the input dwi nifti if dtiinit is selected
if [[ ! ${dtiinit} == "null" ]]; then
        export input_nii_gz=$dtiinit/`jq -r '.files.alignedDwRaw' $dtiinit/dt6.json`
fi

# move thalLatPost to DWI
mri_vol2vol --mov thalLatPost.nii.gz --targ ${input_nii_gz} --o thalLatPostDwi.nii.gz --regheader --nearest
