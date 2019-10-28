#!/bin/bash

set -e

NCORE=8

# make top dirs
mkdir -p track
mkdir -p brainmask
mkdir -p wmc

# set variables
dwi=$(jq -r .dwi config.json)
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
mask=`jq -r '.mask' config.json`
brainmask=`jq -r '.brainmask' config.json`
LMAX=`jq -r '.lmax' config.json`
input_csd=`jq -r "$(eval echo '.lmax$LMAX')" config.json`
rois=`jq -r '.rois' config.json`
count=`jq -r '.count' config.json`
roi1=`jq -r '.seed_roi' config.json`
roi2=`jq -r '.term_roi' config.json`
MINFODAMP=$(jq -r .minfodamp config.json)
minradiusofcurvature=$(jq -r .minradiusofcurvature config.json)
seedspervoxel=$(jq -r .seedspervoxel config.json)

# roi files
ROI1=$rois/ROI${roi1}.nii.gz
ROI2=$rois/ROI${roi2}.nii.gz

# convert dwi to mrtrix format
[ ! -f dwi.b ] && mrconvert -fslgrad $bvecs $bvals $dwi dwi.mif --export_grad_mrtrix dwi.b -nthreads $NCORE

# create mask of dwi
if [[ ${brainmask} == 'null' ]]; then
	[ ! -f mask.mif ] && dwi2mask dwi.mif mask.mif -nthreads $NCORE
else
	echo "brainmask input exists. converting to mrtrix format"
	mrconvert ${brainmask} -stride 1,2,3,4 mask.mif -force -nthreads $NCORE
fi

mrconvert ${mask} -stride 1,2,3,4 5tt.mif -force -nthreads $NCORE

# generate gm-wm interface seed mask
#[ ! -f gmwmi_seed.mif ] && 5tt2gmwmi 5tt.mif gmwmi_seed.mif -force -nthreads $NCORE
#
## generate csf,gm,wm masks
[ ! -f gm.mif ] && mrconvert -coord 3 0 5tt.mif gm.mif -force -nthreads $NCORE
[ ! -f csf.mif ] && mrconvert -coord 3 3 5tt.mif csf.mif -force -nthreads $NCORE
[ ! -f csf.nii.gz ] && mrconvert csf.mif -stride 1,2,3,4 csf.nii.gz -force -nthreads $NCORE
[ ! -f wm.mif ] && mrconvert -coord 3 2 5tt.mif wm.mif -force -nthreads $NCORE
[ ! -f wm.nii.gz ] && mrconvert wm.mif -stride 1,2,3,4 wm.nii.gz -force -nthreads $NCORE

# brainmask
[ ! -f ./brainmask/mask.nii.gz ] && mrconvert mask.mif -stride 1,2,3,4 ./brainmask/mask.nii.gz -force -nthreads $NCORE

# Run trekker
echo "running tracking with Trekker"
/trekker/build/bin/trekker \
	-enableOutputOverwrite \
	-fod ${input_csd} \
	-seed_image ${ROI1} \
	-pathway_A=stop_at_exit ${ROI1} \
	-pathway_A=require_entry wm.nii.gz \
	-pathway_A=discard_if_enters csf.nii.gz \
	-pathway_B=require_entry ${ROI2} \
	-pathway_B=stop_at_exit ${ROI2} \
	-pathway_B=require_entry wm.nii.gz \
	-pathway_B=discard_if_enters csf.nii.gz \
	-stepSize $(jq -r .stepsize config.json) \
	-minRadiusOfCurvature $(jq -r .minradius config.json) \
	-probeRadius 0 \
	-probeLength $(jq -r .probelength config.json) \
	-minLength $(jq -r .min_length config.json) \
	-maxLength $(jq -r .max_length config.json) \
	-seed_count ${count} \
	-seed_countPerVoxel ${seedspervoxel} \
	-minFODamp $(jq -r .minfodamp config.json) \
	-writeColors \
	-verboseLevel 0 \
	-output track.vtk

# convert output vtk to tck
tckconvert track.vtk track/track.tck -force -nthreads $NCORE


# use output.json as product.Json
echo "{\"track\": $(cat track.json)}" > product.json

# clean up
if [ -f ./track/track.tck ]; then
	rm -rf *.mif *.b* ./tmp *.nii.gz
else
	echo "tracking failed"
	exit 1;
fi
