#!/bin/bash

set -x
set -e

NCORE=8

# make top dirs
mkdir -p track
mkdir -p brainmask
mkdir -p wmc
mkdir -p raw

# set variables
dtiinit=`jq -r '.dtiinit' config.json`
dwi=`jq -r '.dwi' config.json`
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
mask=`jq -r '.mask' config.json`
brainmask=`jq -r '.brainmask' config.json`
max_lmax=`jq -r '.lmax' config.json`
rois=`jq -r '.rois' config.json`
count=`jq -r '.count' config.json`
roipair=`jq -r '.roiPair' config.json`
min_fod_amp=`jq -r '.minfodamp' config.json`
curvatures=`jq -r '.curvatures' config.json`
seed_max_trials=`jq -r '.maxtrials' config.json`
max_sampling=`jq -r '.maxsampling' config.json`
lmax2=`jq -r '.lmax2' config.json`
lmax4=`jq -r '.lmax4' config.json`
lmax6=`jq -r '.lmax6' config.json`
lmax8=`jq -r '.lmax8' config.json`
lmax10=`jq -r '.lmax10' config.json`
lmax12=`jq -r '.lmax12' config.json`
lmax14=`jq -r '.lmax14' config.json`
response=`jq -r '.response' config.json`
single_lmax=`jq -r '.single_lmax' config.json`
step_size=`jq -r '.stepsize' config.json`
min_length=`jq -r '.min_length' config.json`
max_length=`jq -r '.max_length' config.json`
probe_length=`jq -r '.probelength' config.json`
probe_quality=`jq -r '.probequality' config.json`
probe_count=`jq -r '.probecount' config.json`
probe_radius=`jq -r '.proberadius' config.json`
v1=`jq -r '.v1' config.json`
exclusion=`jq -r '.exclusion' config.json`

if [ ! -f $rois/ROI${v1}.nii.gz ]; then
    v1=$rois/${v1}.nii.gz
else
    v1=$rois/ROI${v1}.nii.gz
fi

# parse whether dtiinit or dwi input
if [[ ! ${dtiinit} == "null" ]]; then
        input_nii_gz=$dtiinit/*dwi_aligned*.nii.gz
        BVALS=$dtiinit/*.bvals
        BVECS=$dtiinit/*.bvecs
        brainmask=$dtiinit/dti/bin/brainMask.nii.gz
        [ ! -f mask.mif ] && mrconvert ${brainmask} mask.mif -force -nthreads $NCORE
else
	input_nii_gz=${dwi}
fi

# convert input diffusion nifti to mrtrix format
[ ! -f dwi.b ] && mrconvert -fslgrad $bvecs $bvals ${input_nii_gz} dwi.mif --export_grad_mrtrix dwi.b -nthreads $NCORE

# create mask of dwi
if [[ ${brainmask} == 'null' ]]; then
	[ ! -f mask.mif ] && dwi2mask dwi.mif mask.mif -nthreads $NCORE
else
	echo "brainmask input exists. converting to mrtrix format"
	[ ! -f mask.mif ] && mrconvert ${brainmask} -stride 1,2,3,4 mask.mif -force -nthreads $NCORE
fi

# brainmask
[ ! -f ./brainmask/mask.nii.gz ] && mrconvert mask.mif -stride 1,2,3,4 ./brainmask/mask.nii.gz -force -nthreads $NCORE

# 5tt mask
[ ! -f 5tt.mif ] && mrconvert ${mask} -stride 1,2,3,4 5tt.mif -force -nthreads $NCORE

## generate csf,gm,wm masks
[ ! -f gm.mif ] && mrconvert -coord 3 0 5tt.mif gm.mif -force -nthreads $NCORE
[ ! -f csf.mif ] && mrconvert -coord 3 3 5tt.mif csf.mif -force -nthreads $NCORE
[ ! -f csf_bin.nii.gz ] && mrconvert csf.mif -stride 1,2,3,4 csf.nii.gz -force -nthreads $NCORE && fslmaths csf.nii.gz -thr 0.3 -bin csf_bin.nii.gz
[ ! -f wm.mif ] && mrconvert -coord 3 2 5tt.mif wm.mif -force -nthreads $NCORE
[ ! -f wm_bin.nii.gz ] && mrconvert wm.mif -stride 1,2,3,4 wm.nii.gz -force -nthreads $NCORE && fslmaths wm.nii.gz -bin wm_bin.nii.gz