#!/bin/bash

# output lines to log files and fail if error
set -x
set -e

freesurfer=`jq -r '.freesurfer' config.json`
hemispheres=`jq -r '.hemispheres' config.json`

# set dwi as input
input_nii_gz="dwi.nii.gz"

# move aparc aseg in diffusion space
[ ! -f aparc.a2009s.aseg.nii.gz ] && mri_label2vol --seg ${freesurfer}/mri/aparc.a2009s+aseg.mgz --temp ${input_nii_gz} --regheader --o aparc.a2009s.aseg.nii.gz