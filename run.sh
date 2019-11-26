#!/bin/bash

#set -e

NCORE=8

# make top dirs
mkdir -p track
mkdir -p csd
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
fi

ROI1=$rois/ROI${roi1}.nii.gz
ROI2=varea.nii.gz

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

# extract b0 image from dwi
[ ! -f b0.mif ] && dwiextract dwi.mif - -bzero | mrmath - mean b0.mif -axis 3 -nthreads $NCORE

# check if b0 volume successfully created
if [ ! -f b0.mif ]; then
    echo "No b-zero volumes present."
    NSHELL=`mrinfo -shell_bvalues dwi.mif | wc -w`
    NB0s=0
    EB0=''
else
    ISHELL=`mrinfo -shell_bvalues dwi.mif | wc -w`
    NSHELL=$(($ISHELL-1))
    NB0s=`mrinfo -shell_sizes dwi.mif | awk '{print $1}'`
    EB0="0,"
fi

## determine single shell or multishell fit
if [ $NSHELL -gt 1 ]; then
    MS=1
    echo "Multi-shell data: $NSHELL total shells"
else
    echo "Single-shell data: $NSHELL shell"
    MS=0
    if [ ! -z "$TENSOR_FIT" ]; then
	echo "Ignoring requested tensor shell. All data will be fit and tracked on the same b-value."
    fi
fi

## create the correct length of lmax
if [ $NB0s -eq 0 ]; then
    RMAX=${LMAX}
else
    RMAX=0
fi
iter=1

## for every shell (after starting w/ b0), add the max lmax to estimate
while [ $iter -lt $(($NSHELL+1)) ]; do
    
    ## add the $MAXLMAX to the argument
    RMAX=$RMAX,$LMAX

    ## update the iterator
    iter=$(($iter+1))

done

# extract mask
[ ! -f dt.mif ] && dwi2tensor -mask mask.mif dwi.mif dt.mif -bvalue_scaling false -force -nthreads $NCORE


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
	if [ ! -f ./csd/lmax${i_lmax}.nii.gz ]; then
		lmaxvar=$(eval "echo \$lmax${i_lmax}")
		if [[ ${lmaxvar} == 'null' ]]; then
			if [ $MS -eq 0 ]; then
				echo "Estimating CSD response function"
				time dwi2response tournier dwi.mif wmt_${i_lmax}.txt -lmax ${i_lmax} -force -nthreads $NCORE -tempdir ./tmp
			else
				echo "Estimating MSMT CSD response function"
				time dwi2response msmt_5tt dwi.mif 5tt.mif wmt_${i_lmax}.txt gmt_${i_lmax}.txt csf_${i_lmax}.txt -mask mask.mif -lmax ${i_lmax} -tempdir ./tmp -force -nthreads $NCORE
			fi
	
		# fitting CSD FOD of lmax
			if [ $MS -eq 0 ]; then
				echo "Fitting CSD FOD of Lmax ${i_lmax}..."
				time dwi2fod -mask mask.mif csd dwi.mif wmt_${i_lmax}.txt wmt_lmax${i_lmax}_fod.mif -lmax ${i_lmax} -force -nthreads $NCORE
			else
				echo "Estimating MSMT CSD FOD of Lmax ${i_lmax}"
				time dwi2fod msmt_csd dwi.mif wmt_${i_lmax}.txt wmt_lmax${i_lmax}_fod.mif  gmt_${i_lmax}.txt gmt_lmax${i_lmax}_fod.mif csf_${i_lmax}.txt csf_lmax${i_lmax}_fod.mif -force -nthreads $NCORE
			fi
			# convert to niftis
			mrconvert wmt_lmax${i_lmax}_fod.mif -stride 1,2,3,4 ./csd/lmax${i_lmax}.nii.gz -force -nthreads $NCORE
	
		else
			echo "csd already inputted. skipping csd generation"
	                cp ${lmaxvar} ./csd/
		fi
	else
		echo "csd exists. skipping"
	fi
done


for (( i_lmax=2; i_lmax<=$MAXLMAX; i_lmax+=2 )); do
	# Run trekker
	echo "running tracking on lmax ${i_lmax} with Trekker"
	/trekker/build/bin/trekker \
		-enableOutputOverwrite \
		-fod ./csd/lmax${i_lmax}.nii.gz \
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
		-verboseLevel 0 \
		-output track_${i_lmax}.vtk
	
	# convert output vtk to tck
	tckconvert track_${i_lmax}.vtk track_${i_lmax}.tck -force -nthreads $NCORE
done

## concatenate tracts
holder=(*tract*.tck)
cat_tracks ./track/track.tck ${holder[*]}
if [ ! $ret -eq 0 ]; then
    exit $ret
fi
rm -rf ${holder[*]}

# use output.json as product.Json
tckinfo ./track/track.tck > product.json

# clean up
if [ -f ./track/track.tck ]; then
	rm -rf *.mif *.b* ./tmp *.nii.gz
else
	echo "tracking failed"
	exit 1;
fi
