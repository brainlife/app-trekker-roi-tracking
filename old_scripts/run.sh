#!/bin/bash

set -x
#set -e

NCORE=8

# make directories for output
mkdir -p track #tck
mkdir -p mask #5tt mask
mkdir -p brainmask #brainmask
mkdir -p wmc #classification structure

# set variables
dwi=$(jq -r .dwi config.json) # dwi input
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
anat=`jq -r '.t1' config.json` # used for csd generation if csds not inputted
mask=`jq -r '.mask' config.json` # 5tt mask
brainmask=`jq -r '.brainmask' config.json` # dwi brainmask
MAXLMAX=`jq -r '.maxlmax' config.json` # max lmax. must be above 6 currently
rois=`jq -r '.rois' config.json` # roi directory
count=`jq -r '.count' config.json` # streamline count per iteration
roi1=`jq -r '.seed_roi' config.json` # seed roi (i.e. left or right lgn)
MINFODAMP=$(jq -r .minfodamp config.json) # minimum fod amplitude
seedmaxtrials=$(jq -r .maxtrials config.json) # maximum seeds per trial. increase if not reaching desired streamline counts
maxsampling=$(jq -r .maxsampling config.json) # maximum sampling. increase if not reaching desired streamline counts
dtiinit=`jq -r '.dtiinit' config.json` # dtiinit input
lmax2=`jq -r '.lmax2' config.json` # lmax2
lmax4=`jq -r '.lmax4' config.json` # lmax4
lmax6=`jq -r '.lmax6' config.json` # lmax6
lmax8=`jq -r '.lmax8' config.json` # lmax8
lmax10=`jq -r '.lmax10' config.json` # lmax10
lmax12=`jq -r '.lmax12' config.json` # lmax12
lmax14=`jq -r '.lmax14' config.json` # lmax14

# set seed and term roi inputs
ROI1=$rois/ROI${roi1}.nii.gz # seed roi (i.e. left or right lgn)
farperiph="Ecc30to90.nii.gz"
periph="Ecc15to30.nii.gz"
mac="Ecc0to3.nii.gz"

# set curvature parameterse
#farperiph_periph_curv=.5
#mac_curv=.8

# if dtiinit is inputted, set appropriate fields 
if [[ ! ${dtiinit} == "null" ]]; then
	dwi=$dtiinit/*dwi_aligned*.nii.gz
	bvals=$dtiinit/*.bvals
	bvecs=$dtiinit/*.bvecs
	brainmask=$dtiinit/dti/bin/brainMask.nii.gz
fi


# convert dwi to mrtrix format
[ ! -f dwi.b ] && mrconvert -fslgrad $bvecs $bvals $dwi dwi.mif --export_grad_mrtrix dwi.b -nthreads $NCORE

# create mask of dwi
if [[ ${brainmask} == 'null' ]]; then
	[ ! -f mask.mif ] && dwi2mask dwi.mif mask.mif -nthreads $NCORE
else
	echo "brainmask input exists. converting to mrtrix format"
	mrconvert ${brainmask} -stride 1,2,3,4 mask.mif -force -nthreads $NCORE
fi

# convert to mif and move to brainmask output directory
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
	[ ! -f csf_bin.nii.gz ] && fslmaths csf.nii.gz -bin csf_bin.nii.gz
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

# far periphery
echo "${farperiph}"
for (( i_lmax=2; i_lmax<=$MAXLMAX; i_lmax+=2 )); do
	for farperiph_periph_curv in 0.2 0.25 0.3 0.35 0.4; do
		if [ ! -f track_${farperiph}_${i_lmax}_${farperiph_periph_curv}.tck ]; then
			# Run trekker
			echo "running tracking on lmax ${i_lmax} with Trekker"
			/trekker/build/bin/trekker \
				-enableOutputOverwrite \
				-fod lmax${i_lmax}.nii.gz \
				-seed_image ${ROI1} \
				-pathway_A=stop_at_exit ${ROI1} \
				-pathway_A=discard_if_enters csf_bin.nii.gz \
				-pathway_B=require_entry ${farperiph} \
				-pathway_B=discard_if_enters csf_bin.nii.gz \
				-pathway_B=stop_at_exit ${farperiph} \
				-stepSize $(jq -r .stepsize config.json) \
				-minRadiusOfCurvature ${farperiph_periph_curv} \
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
				-output track_${farperiph}_${i_lmax}_${farperiph_periph_curv}.vtk \
				-numberOfThreads $NCORE \
				-useBestAtInit
			
			# convert output vtk to tck
			tckconvert track_${farperiph}_${i_lmax}_${farperiph_periph_curv}.vtk track_${farperiph}_${i_lmax}_${farperiph_periph_curv}.tck -force -nthreads $NCORE
		fi
	done
done

holder=(*track_${farperiph}*.tck)
tckedit ${holder[*]} ./track_${farperiph}.tck

# periphery
echo "${periph}"
for (( i_lmax=2; i_lmax<=$MAXLMAX; i_lmax+=2 )); do
	for farperiph_periph_curv in 0.3 0.4 0.5 0.6 0.7; do
		if [ ! -f track_${periph}_${i_lmax}_${farperiph_periph_curv}.tck ]; then
			# Run trekker
			echo "running tracking on lmax ${i_lmax} with Trekker"
			/trekker/build/bin/trekker \
				-enableOutputOverwrite \
				-fod lmax${i_lmax}.nii.gz \
				-seed_image ${ROI1} \
				-pathway_A=stop_at_exit ${ROI1} \
				-pathway_A=discard_if_enters csf_bin.nii.gz \
				-pathway_B=require_entry ${periph} \
				-pathway_B=discard_if_enters csf_bin.nii.gz \
				-pathway_B=stop_at_exit ${periph} \
				-stepSize $(jq -r .stepsize config.json) \
				-minRadiusOfCurvature ${farperiph_periph_curv} \
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
				-output track_${periph}_${i_lmax}_${farperiph_periph_curv}.vtk \
				-numberOfThreads $NCORE \
				-useBestAtInit		

			# convert output vtk to tck
			tckconvert track_${periph}_${i_lmax}_${farperiph_periph_curv}.vtk track_${periph}_${i_lmax}_${farperiph_periph_curv}.tck -force -nthreads $NCORE
		fi
	done
done

holder=(*track_${periph}*.tck)
tckedit ${holder[*]} ./track_${periph}.tck

# macular
echo "${mac}"
for (( i_lmax=2; i_lmax<=$MAXLMAX; i_lmax+=2 )); do
	for mac_curv in 0.6 0.7 0.8 0.9 1; do
		if [ ! -f track_${mac}_${i_lmax}_${mac_curv}.tck ]; then
			# Run trekker
			echo "running tracking on lmax ${i_lmax} with Trekker"
			/trekker/build/bin/trekker \
				-enableOutputOverwrite \
				-fod lmax${i_lmax}.nii.gz \
				-seed_image ${ROI1} \
				-pathway_A=stop_at_exit ${ROI1} \
				-pathway_A=discard_if_enters csf_bin.nii.gz \
				-pathway_B=require_entry ${mac} \
				-pathway_B=discard_if_enters csf_bin.nii.gz \
				-pathway_B=stop_at_exit ${mac} \
				-stepSize $(jq -r .stepsize config.json) \
				-minRadiusOfCurvature ${mac_curv} \
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
				-output track_${mac}_${i_lmax}_${mac_curv}.vtk \
				-numberOfThreads $NCORE \
				-useBestAtInit

			# convert output vtk to tck
			tckconvert track_${mac}_${i_lmax}_${mac_curv}.vtk track_${mac}_${i_lmax}_${mac_curv}.tck -force -nthreads $NCORE
		fi
	done
done

holder=(*track_${mac}*.tck)
tckedit ${holder[*]} ./track_${mac}.tck

# concatenate tracts
#holder=(track_${farperiph}.tck track_${periph}.tck track_${mac}.tck)
#tckedit ${holder[*]} ./track/track.tck
#if [ ! $ret -eq 0 ]; then
#    exit $ret
#fi
#rm -rf ${holder[*]}
#
## use output.json as product.Json
#tckinfo ./track/track.tck > product.json

# clean up
#if [ -f ./track/track.tck ]; then
#	rm -rf *.mif *.b* ./tmp *.vtk* *track*.json
#else
#	echo "tracking failed"
#	exit 1;
#fi
