#!/bin/bash

#set -e

NCORE=8

# make top dirs
mkdir -p track
mkdir -p brainmask
mkdir -p wmc
mkdir -p csd
mkdir -p 5tt

# set variables
anat=`jq -r '.anat' config.json`
dtiinit=`jq -r '.dtiinit' config.json`
dwi=$(jq -r .dwi config.json)
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
mask=`jq -r '.mask' config.json`
brainmask=`jq -r '.brainmask' config.json`
max_lmax=`jq -r '.lmax' config.json`
rois=`jq -r '.rois' config.json`
count=`jq -r '.count' config.json`
roi1=`jq -r '.seed_roi' config.json`
roi2=`jq -r '.term_roi' config.json`
min_fod_amp=$(jq -r .minfodamp config.json)
curvatures=$(jq -r .curvatures config.json)
seed_max_trials=$(jq -r .maxtrials config.json)
max_sampling=$(jq -r .maxsampling config.json)
lmax2=`jq -r '.lmax2' config.json`
lmax4=`jq -r '.lmax2' config.json`
lmax6=`jq -r '.lmax2' config.json`
lmax8=`jq -r '.lmax2' config.json`
lmax10=`jq -r '.lmax2' config.json`
lmax12=`jq -r '.lmax2' config.json`
lmax14=`jq -r '.lmax2' config.json`
response=`jq -r '.response' config.json`
single_lmax=`jq -r '.single_lmax' config.json`
multiple_seeds=`jq -r '.multiple_seeds' config.json`
step_size=`jq -r '.stepsize' config.json`
min_length=`jq -r '.min_length' config.json`
max_length=`jq -r '.max_length' config.json`
probe_length=`jq -r '.probelength' config.json`
probe_quality=`jq -r '.probequality' config.json`
probe_count=`jq -r '.probecount' config.json`
probe_radius=`jq -r '.proberadius' config.json`

# if maximum lmax is not inputted, calculate based on number of volumes
if [[ $max_lmax == "null" || -z $max_lmax ]]; then
    echo "max_lmax is empty... determining which lmax to use from .bvals"
    max_lmax=`./calculatelmax.py`
fi

# roi files
ROI1=$rois/ROI${roi1}.nii.gz
ROI2=$rois/ROI${roi2}.nii.gz

# merge rois if seeding in both rois is preferred
if [[ ${multiple_seeds} == true ]]; then
	mrcalc ${ROI1} ${ROI2} -add seed.nii.gz
	seed=seed.nii.gz
else
	seed=${ROI1}
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

# generate 5-tissue-type (5TT) tracking mask
if [[ ${mask} == 'null' ]]; then
	[ ! -f anat.mif ] && mrconvert ${anat} anat.mif -force -nthreads $NCORE
	[ ! -f 5tt.mif ] && 5ttgen fsl anat.mif 5tt.mif -nocrop -sgm_amyg_hipp -tempdir ./tmp -force -nthreads $NCORE
else
	echo "input 5tt mask exists. converting to mrtrix format"
	[ ! -f 5tt.mif ] && mrconvert ${mask} -stride 1,2,3,4 5tt.mif -force -nthreads $NCORE
fi

## generate csf,gm,wm masks
[ ! -f gm.mif ] && mrconvert -coord 3 0 5tt.mif gm.mif -force -nthreads $NCORE
[ ! -f csf.mif ] && mrconvert -coord 3 3 5tt.mif csf.mif -force -nthreads $NCORE
[ ! -f csf.nii.gz ] && mrconvert csf.mif -stride 1,2,3,4 csf.nii.gz -force -nthreads $NCORE
[ ! -f wm.mif ] && mrconvert -coord 3 2 5tt.mif wm.mif -force -nthreads $NCORE
[ ! -f wm.nii.gz ] && mrconvert wm.mif -stride 1,2,3,4 wm.nii.gz -force -nthreads $NCORE
[ ! -f ./5tt/mask.nii.gz ] && mrconvert 5tt.mif -stride 1,2,3,4 ./5tt/mask.nii.gz -force -nthreads $NCORE

# brainmask
[ ! -f ./brainmask/mask.nii.gz ] && mrconvert mask.mif -stride 1,2,3,4 ./brainmask/mask.nii.gz -force -nthreads $NCORE

# generate sequence of lmax spherical harmonic order for single or ensemble
if [[ ${single_lmax} == true ]]; then
	lmaxs=$(seq ${max_lmax} ${max_lmax})
else
	lmaxs=$(seq 2 2 ${max_lmax})
fi

# if csd does not already exist for specific lmax, generate using mrtrix3.0. Code grabbed from Brent McPherson's brainlife app app-mrtrix3-act
for LMAXS in ${lmaxs}; do
	input_csd=$(eval "echo \$lmax${LMAXS}")
	if [[ ${input_csd} == 'null' ]]; then
		if [ $MS -eq 0 ]; then
			echo "Estimating CSD response function"
			time dwi2response tournier dwi.mif wmt.txt -lmax ${LMAXS} -force -nthreads $NCORE -tempdir ./tmp
			echo "Fitting CSD FOD of Lmax ${LMAXS}..."
			time dwi2fod -mask mask.mif csd dwi.mif wmt.txt wmt_lmax${LMAXS}_fod.mif -lmax ${LMAXS} -force -nthreads $NCORE
		else
			echo "Estimating MSMT CSD response function"
			time dwi2response msmt_5tt dwi.mif 5tt.mif wmt.txt gmt.txt csf.txt -mask mask.mif -lmax ${LMAXS} -tempdir ./tmp -force -nthreads $NCORE
			echo "Estimating MSMT CSD FOD of Lmax ${LMAXS}"
			time dwi2fod msmt_csd dwi.mif wmt.txt wmt_lmax${LMAXS}_fod.mif  gmt.txt gmt_lmax${LMAXS}_fod.mif csf.txt csf_lmax${LMAXS}_fod.mif -force -nthreads $NCORE
		fi
		# convert to niftis
		mrconvert wmt_lmax${LMAXS}_fod.mif -stride 1,2,3,4 ./csd/lmax${LMAXS}.nii.gz -force -nthreads $NCORE
	
		# copy response file
		cp wmt.txt response.txt
	else
		echo "csd already inputted. skipping csd generation"
		cp -v ${input_csd} ./csd/lmax${LMAXS}.nii.gz
	fi
done

# Run trekker
for LMAX in ${lmaxs}; do
	input_csd=./csd/lmax${LMAXS}.nii.gz
	echo "running tracking with Trekker on lmax ${LMAXS}"
	for CURV in ${curvatures}; do
		echo "curvature ${CURV}"
		if [ ! -f track_lmax${LMAXS}_curv${CURV}.vtk ]; then
			/trekker/build/bin/trekker \
				-enableOutputOverwrite \
				-fod ${input_csd} \
				-seed_image ${seed} \
				-pathway_A=stop_at_exit ${ROI1} \
				-pathway_A=discard_if_enters csf.nii.gz \
				-pathway_B=require_entry ${ROI2} \
				-pathway_B=stop_at_exit ${ROI2} \
				-pathway_B=discard_if_enters csf.nii.gz \
				-stepSize ${step_size} \
				-minRadiusOfCurvature ${CURV} \
				-probeRadius ${probe_radius} \
				-probeCount ${probe_count} \
				-probeQuality ${probe_quality} \
				-probeLength ${probe_length} \
				-minLength ${min_length} \
				-maxLength ${max_length} \
				-seed_count ${count} \
				-seed_maxTrials ${seed_max_trials} \
				-maxSamplingPerStep ${max_sampling} \
				-minFODamp ${min_fod_amp} \
				-writeColors \
				-verboseLevel 1 \
				-numberOfThreads $NCORE \
				-output track_lmax${LMAXS}_curv${CURV}.vtk

				# convert output vtk to tck
				tckconvert track_lmax${LMAXS}_curv${CURV}.vtk track_lmax${LMAXS}_curv${CURV}.tck -force -nthreads $NCORE
			fi
		done
	done

# merge tracks together
holder=(*.tck)
tckedit ${holder[*]} ./track/track.tck -force -nthreads $NCORE -quiet

# use output.json as product.Json
echo "{\"track\": $(eval 'tckinfo ./track/track.tck')}" > product.json

# clean up
#if [ -f ./track/track.tck ]; then
#	rm -rf *.mif *.b* ./tmp *.nii.gz *track_*
#else
#	echo "tracking failed"
#	exit 1;
#fi
