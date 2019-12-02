#!/bin/bash

#set -e

NCORE=8

# make top dirs
mkdir -p track
mkdir -p mask
mkdir -p brainmask
mkdir -p wmc

# set variables
dwi=$(jq -r .dwi config.json)
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
anat=`jq -r '.t1' config.json`
mask=`jq -r '.mask' config.json`
brainmask=`jq -r '.brainmask' config.json`
MAXLMAX=`jq -r '.maxlmax' config.json`
rois=`jq -r '.rois' config.json`
count=`jq -r '.count' config.json`
roi1=`jq -r '.seed_roi' config.json`
eccentricity=`jq -r '.ecc' config.json`
MINFODAMP=$(jq -r .minfodamp config.json)
seedmaxtrials=$(jq -r .maxtrials config.json)
maxsampling=$(jq -r .maxsampling config.json)
dtiinit=`jq -r '.dtiinit' config.json`
lmax2=`jq -r '.lmax2' config.json`
lmax4=`jq -r '.lmax4' config.json`
lmax6=`jq -r '.lmax6' config.json`
lmax8=`jq -r '.lmax8' config.json`
lmax10=`jq -r '.lmax10' config.json`
lmax12=`jq -r '.lmax12' config.json`
lmax14=`jq -r '.lmax14' config.json`


if [[ ! ${dtiinit} == "null" ]]; then
	dwi=$dtiinit/*dwi_aligned*.nii.gz
	bvals=$dtiinit/*.bvals
	bvecs=$dtiinit/*.bvecs
	brainmask=$dtiinit/dti/bin/brainMask.nii.gz
fi

ROI1=$rois/ROI${roi1}.nii.gz
ROI2=v1.nii.gz

# convert dwi to mrtrix format
[ ! -f dwi.b ] && mrconvert -fslgrad $bvecs $bvals $dwi dwi.mif --export_grad_mrtrix dwi.b -nthreads $NCORE

# create mask of dwi
if [[ ${brainmask} == 'null' ]]; then
	[ ! -f mask.mif ] && dwi2mask dwi.mif mask.mif -nthreads $NCORE
else
	echo "brainmask input exists. converting to mrtrix format"
	mrconvert ${brainmask} -stride 1,2,3,4 mask.mif -force -nthreads $NCORE
fi

# brainmask
[ ! -f ./brainmask/mask.nii.gz ] && mrconvert mask.mif -stride 1,2,3,4 ./brainmask/mask.nii.gz -force -nthreads $NCORE

# convert anatomical t1 to mrtrix format
[ ! -f anat.mif ] && mrconvert ${anat} anat.mif -nthreads $NCORE

# generate 5-tissue-type (5TT) tracking mask
if [ ! -f csf.nii.gz ]; then
	if [[ ${mask} == 'null' ]]; then
		[ ! -f 5tt.mif ] && 5ttgen fsl anat.mif 5tt.mif -nocrop -sgm_amyg_hipp -tempdir ./tmp -force -nthreads $NCORE
	else
		echo "input 5tt mask exists. converting to mrtrix format"
		mrconvert ${mask} -stride 1,2,3,4 5tt.mif -force -nthreads $NCORE
	fi
	
	# 5 tissue type visualization
	[ ! -f ./mask/mask.nii.gz ] && mrconvert 5tt.mif -stride 1,2,3,4 ./mask/mask.nii.gz -force -nthreads $NCORE

	[ ! -f csf.mif ] && mrconvert -coord 3 3 5tt.mif csf.mif -force -nthreads $NCORE
	[ ! -f csf.nii.gz ] && mrconvert csf.mif -stride 1,2,3,4 csf.nii.gz -force -nthreads $NCORE
else
	echo "csf mask already exits. skipping"
fi

#creating response (should take about 15min)
for (( i_lmax=2; i_lmax<=$MAXLMAX; i_lmax+=2 )); do
	if [ ! -f lmax${i_lmax}.nii.gz ]; then
		lmaxvar=$(eval "echo \$lmax${i_lmax}")
		echo "csd already inputted. skipping csd generation"
	        cp ${lmaxvar} ./
	else
		echo "csd exists. skipping"
	fi
done

for (( i_lmax=2; i_lmax<=$MAXLMAX; i_lmax+=2 )); do
	# Run trekker
	echo "running tracking on lmax ${i_lmax} with Trekker"
	/trekker/build/bin/trekker \
		-enableOutputOverwrite \
		-fod lmax${i_lmax}.nii.gz \
		-seed_image ${ROI1} \
		-pathway_A=stop_at_exit ${ROI1} \
		-pathway_A=discard_if_enters csf.nii.gz \
		-pathway_B=require_entry ${ROI2} \
		-pathway_B=discard_if_enters csf.nii.gz \
		-pathway_B=stop_at_exit ${ROI2} \
		-stepSize $(jq -r .stepsize config.json) \
		-minRadiusOfCurvature $(jq -r .minradius config.json) \
		-probeRadius 0 \
		-probeLength $(jq -r .probelength config.json) \
		-minLength $(jq -r .min_length config.json) \
		-maxLength $(jq -r .max_length config.json) \
		-seed_count ${count} \
		-seed_maxTrials ${seedmaxtrials} \
		-maxSamplingPerStep ${maxsampling} \
		-minFODamp $(jq -r .minfodamp config.json) \
		-writeColors \
		-verboseLevel 1 \
		-output track_${i_lmax}.vtk
	
	# convert output vtk to tck
	tckconvert track_${i_lmax}.vtk track_${i_lmax}.tck -force -nthreads $NCORE
done

## concatenate tracts
holder=(*track*.tck)
tckedit ${holder[*]} ./track/track.tck
if [ ! $ret -eq 0 ]; then
    exit $ret
fi
rm -rf ${holder[*]}

# use output.json as product.Json
tckinfo ./track/track.tck > product.json

# clean up
if [ -f ./track/track.tck ]; then
	rm -rf *.mif *.b* ./tmp *.nii.gz *.vtk* *track*.json
else
	echo "tracking failed"
	exit 1;
fi
