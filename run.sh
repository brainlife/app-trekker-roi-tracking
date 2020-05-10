#!/bin/bash

set -x
set -e

NCORE=8

# make top dirs
mkdir -p track
mkdir -p brainmask
mkdir -p wmc
mkdir -p 5tt
mkdir -p raw

# set variables
anat=`jq -r '.anat' config.json`
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
#multiple_seed=`jq -r '.multiple_seed' config.json`
reslice=`jq -r '.reslice' config.json`
step_size=`jq -r '.stepsize' config.json`
min_length=`jq -r '.min_length' config.json`
max_length=`jq -r '.max_length' config.json`
probe_length=`jq -r '.probelength' config.json`
probe_quality=`jq -r '.probequality' config.json`
probe_count=`jq -r '.probecount' config.json`
probe_radius=`jq -r '.proberadius' config.json`

if [ "$reslice" == "true" ]; then
    echo "using resliced_rois"
    rois=resliced_rois
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
[ ! -f csf_bin.nii.gz ] && mrconvert csf.mif -stride 1,2,3,4 csf.nii.gz -force -nthreads $NCORE && fslmaths csf.nii.gz -thr 0.5 -bin csf_bin.nii.gz
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

# # extract b0 image from dwi
# [ ! -f b0.mif ] && dwiextract dwi.mif - -bzero | mrmath - mean b0.mif -axis 3 -nthreads $NCORE

# # check if b0 volume successfully created
# if [ ! -f b0.mif ]; then
#     echo "No b-zero volumes present."
#     NSHELL=`mrinfo -shell_bvalues dwi.mif | wc -w`
#     NB0s=0
#     EB0=''
# else
#     ISHELL=`mrinfo -shell_bvalues dwi.mif | wc -w`
#     NSHELL=$(($ISHELL-1))
#     NB0s=`mrinfo -shell_sizes dwi.mif | awk '{print $1}'`
#     EB0="0,"
# fi

# ## determine single shell or multishell fit
# if [ $NSHELL -gt 1 ]; then
#     MS=1
#     echo "Multi-shell data: $NSHELL total shells"
# else
#     echo "Single-shell data: $NSHELL shell"
#     MS=0
#     if [ ! -z "$TENSOR_FIT" ]; then
# 	echo "Ignoring requested tensor shell. All data will be fit and tracked on the same b-value."
#     fi
# fi

# ## create the correct length of lmax
# if [ $NB0s -eq 0 ]; then
#     RMAX=${LMAX}
# else
#     RMAX=0
# fi
# iter=1

# ## for every shell (after starting w/ b0), add the max lmax to estimate
# while [ $iter -lt $(($NSHELL+1)) ]; do
    
#     ## add the $MAXLMAX to the argument
#     RMAX=$RMAX,$LMAX

#     ## update the iterator
#     iter=$(($iter+1))

# done

# # if csd does not already exist for specific lmax, generate using mrtrix3.0. Code grabbed from Brent McPherson's brainlife app app-mrtrix3-act
# for LMAXS in ${lmaxs}; do
# 	input_csd=$(eval "echo \$lmax${LMAXS}")
# 	if [[ ${input_csd} == 'null' ]]; then
# 		if [ $MS -eq 0 ]; then
# 			echo "Estimating CSD response function"
# 			time dwi2response tournier dwi.mif wmt_lmax${LMAXS}.txt -lmax ${LMAXS} -force -nthreads $NCORE -tempdir ./tmp
# 			echo "Fitting CSD FOD of Lmax ${LMAXS}..."
# 			time dwi2fod -mask mask.mif csd dwi.mif wmt_lmax${LMAXS}.txt wmt_lmax${LMAXS}_fod.mif -lmax ${LMAXS} -force -nthreads $NCORE
# 		else
# 			echo "Estimating MSMT CSD response function"
# 			time dwi2response msmt_5tt dwi.mif 5tt.mif wmt_lmax${LMAXS}.txt gmt_lmax${LMAXS}.txt csf_lmax${LMAXS}.txt -mask mask.mif -lmax ${LMAXS} -tempdir ./tmp -force -nthreads $NCORE
# 			echo "Estimating MSMT CSD FOD of Lmax ${LMAXS}"
# 			time dwi2fod msmt_csd dwi.mif wmt_lmax${LMAXS}.txt wmt_lmax${LMAXS}_fod.mif  gmt_lmax${LMAXS}.txt gmt_lmax${LMAXS}_fod.mif csf_lmax${LMAXS}.txt csf_lmax${LMAXS}_fod.mif -force -nthreads $NCORE
# 		fi
# 		# convert to niftis
# 		mrconvert wmt_lmax${LMAXS}_fod.mif -stride 1,2,3,4 ./csd/lmax${LMAXS}.nii.gz -force -nthreads $NCORE
	
# 		# copy response file
# 		if [[ ${LMAXS} == ${lmax} ]]; then
# 			cp wmt_lmax${LMAXS}.txt response.txt
# 		fi
# 	else
# 		echo "csd already inputted. skipping csd generation"
# 		cp -v ${input_csd} ./csd/lmax${LMAXS}.nii.gz
# 	fi
# done

# Run trekker
pairs=($roipair)
range=` expr ${#pairs[@]}`
nTracts=` expr ${range} / 2`


for (( i=0; i<$nTracts; i+=1 )); do
	[ -f track$((i+1)).tck ] && continue

	echo "creating seed for tract $((i+1))"
	if [ ! -f $rois/ROI${pairs[$((i*2))]}.nii.gz ]; then
		roi1=$rois/${pairs[$((i*2))]}.nii.gz
	else
		roi1=$rois/ROI${pairs[$((i*2))]}.nii.gz
	fi

	if [ ! -f $rois/ROI${pairs[$((i*2+1))]}.nii.gz ]; then
		roi2=$rois/${pairs[$((i*2+1))]}.nii.gz
	else
		roi2=$rois/ROI${pairs[$((i*2+1))]}.nii.gz
	fi

	# NEED TO FIGURE OUT HOW TO BEST INTERACT WITH THE PATHWAY RULES WHEN USING MULTIPLE SEEDS. FOR NOW, NOT ALLOWING IT
	# if [[ ${multiple_seed} == true ]]; then
	# 	seed=seed_${pairs[$((i*2))]}_${pairs[$((i*2+1))]}.nii.gz
	# 	[ ! -f $seed ] && mrcalc $roi1 $roi2 -add $seed -force -quiet -nthreads $NCORE && fslmaths $seed -bin $seed
	# else
	# 	seed=$roi1
	# fi


	for LMAXS in ${lmaxs}; do
		input_csd=$(eval "echo \$lmax${LMAXS}")
		echo "running tracking with Trekker on lmax ${LMAXS}"
		for CURV in ${curvatures}; do
			echo "curvature ${CURV}"
			for STEP in ${step_size}; do
				echo "step size ${STEP}"
				for FOD in ${min_fod_amp}; do
					echo "FOD amplitude ${FOD}"
					if [ ! -f track$((i+1))_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.vtk ]; then
						/trekker/build/bin/trekker \
							-enableOutputOverwrite \
							-fod ${input_csd} \
							-seed_image ${roi1} \
							-pathway=require_entry ${roi2} \
							-pathway=stop_at_entry ${roi2} \
							-pathway=discard_if_enters csf_bin.nii.gz \
							-stepSize ${STEP} \
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
							-minFODamp ${FOD} \
							-writeColors \
							-verboseLevel 0 \
							-numberOfThreads $NCORE \
							-useBestAtInit \
							-output track$((i+1))_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.vtk

							# convert output vtk to tck
							tckconvert track$((i+1))_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.vtk track$((i+1))_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.tck -force -nthreads $NCORE
						fi
					done
				done
			done
		done
		
		output=track$((i+1)).tck
		tcks=(track$((i+1))*.tck)
		if [ ${#tcks[@]} == 1 ]; then
			mv ${tcks[0]} $output
		else
			tckedit ${tcks[*]} $output
			mv ${tcks[*]} ./raw/
		fi
		tckinfo $output > track_info$((i+1)).txt
	done

if [ -f track*.tck ]; then
	mv *.mif *.b* ./tmp *.nii.gz ./raw/
	holder=(track$((i+1))*.tck)
        tckedit ${holder[*]} ./track/track.tck
        tckinfo ./track/track.tck > track_info.txt
else
	echo "tracking did not generate. please check derivatives and log files for debugging"
	exit 1
fi

