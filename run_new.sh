#!/bin/bash

#set -x
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
dwi=`jq -r '.dwi' config.json`
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
mask=`jq -r '.mask' config.json`
brainmask=`jq -r '.brainmask' config.json`
max_lmax=`jq -r '.maxlmax' config.json`
rois=`jq -r '.rois' config.json`
count=`jq -r '.count' config.json`
roi1=`jq -r '.seed_roi' config.json`
roi2=`jq -r '.term_roi' config.json`
min_fod_amp=`jq -r '.minfodamp' config.json`
seedmaxtrials=`jq -r '.maxtrials' config.json`
maxsampling=`jq -r '.maxsampling' config.json`
lmax2=`jq -r '.lmax2' config.json`
lmax4=`jq -r '.lmax2' config.json`
lmax6=`jq -r '.lmax2' config.json`
lmax8=`jq -r '.lmax2' config.json`
lmax10=`jq -r '.lmax2' config.json`
lmax12=`jq -r '.lmax2' config.json`
lmax14=`jq -r '.lmax2' config.json`
response=`jq -r '.response' config.json`
single_lmax=`jq -r '.single_lmax' config.json`
Step=`jq -r '.stepsize' config.json`
min_length=`jq -r '.min_length' config.json`
max_length=`jq -r '.max_length' config.json`
probe_length=`jq -r '.probelength' config.json`
probe_quality=`jq -r '.probequality' config.json`
probe_count=`jq -r '.probecount' config.json`
probe_radius=`jq -r '.proberadius' config.json`
min_degree=`jq -r '.MinDegree' config.json`
max_degree=`jq -r '.MaxDegree' config.json`
#farperiph_curv=`jq -r '.farperiph_curv' config.json`
#periph_curv=`jq -r '.periph_curv' config.json`
#mac_curv=`jq -r '.mac_curv' config.json`
multiple_seeds=`jq -r '.multiple_seeds' config.json`
track=`jq -r '.track' config.json`
Curv=`jq -r '.curv' config.json`

# if maximum lmax is not inputted, calculate based on number of volumes
if [[ $max_lmax == "null" || -z $max_lmax ]]; then
    echo "max_lmax is empty... determining which lmax to use from .bvals"
    max_lmax=`./calculatelmax.py`
fi

# roi files
ROI1=$rois/ROI${roi1}.nii.gz

if [[ ${track} == 'farperiph' ]]; then
	track_roi="Ecc$(echo ${min_degree} | cut -d' ' -f3)to$(echo ${max_degree} | cut -d' ' -f3)"
elif [[ ${track} == 'periph' ]]; then
	track_roi="Ecc$(echo ${min_degree} | cut -d' ' -f2)to$(echo ${max_degree} | cut -d' ' -f2)"
else
	track_roi="Ecc$(echo ${min_degree} | cut -d' ' -f1)to$(echo ${max_degree} | cut -d' ' -f1)"
fi
#periph_roi="Ecc$(echo ${min_degree} | cut -d' ' -f2)to$(echo ${max_degree} | cut -d' ' -f2)"
#farperiph_roi="Ecc$(echo ${min_degree} | cut -d' ' -f3)to$(echo ${max_degree} | cut -d' ' -f3)"


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
[ ! -f csf_bin.nii.gz ] && mrconvert csf.mif -stride 1,2,3,4 csf.nii.gz -force -nthreads $NCORE && fslmaths csf.nii.gz -bin csf_bin.nii.gz
[ ! -f wm.mif ] && mrconvert -coord 3 2 5tt.mif wm.mif -force -nthreads $NCORE
[ ! -f wm_bin.nii.gz ] && mrconvert wm.mif -stride 1,2,3,4 wm.nii.gz -force -nthreads $NCORE && fslmaths wm.nii.gz -bin wm_bin.nii.gz
[ ! -f ./5tt/mask.nii.gz ] && mrconvert 5tt.mif -stride 1,2,3,4 ./5tt/mask.nii.gz -force -nthreads $NCORE

# brainmask
[ ! -f ./brainmask/mask.nii.gz ] && mrconvert mask.mif -stride 1,2,3,4 ./brainmask/mask.nii.gz -force -nthreads $NCORE

# generate sequence of lmax spherical harmonic order for single or ensemble
if [[ ${single_lmax} == true ]]; then
	lmaxs=$(seq ${max_lmax} ${max_lmax})
else
	lmaxs=$(seq 2 2 ${max_lmax})
fi

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

# if csd does not already exist for specific lmax, generate using mrtrix3.0. Code grabbed from Brent McPherson's brainlife app app-mrtrix3-act
for LMAXS in ${lmaxs}; do
	input_csd=$(eval "echo \$lmax${LMAXS}")
	if [[ ${input_csd} == 'null' ]]; then
		if [ $MS -eq 0 ]; then
			echo "Estimating CSD response function"
			time dwi2response tournier dwi.mif wmt_lmax${LMAXS}.txt -lmax ${LMAXS} -force -nthreads $NCORE -tempdir ./tmp
			echo "Fitting CSD FOD of Lmax ${LMAXS}..."
			time dwi2fod -mask mask.mif csd dwi.mif wmt_lmax${LMAXS}.txt wmt_lmax${LMAXS}_fod.mif -lmax ${LMAXS} -force -nthreads $NCORE
		else
			echo "Estimating MSMT CSD response function"
			time dwi2response msmt_5tt dwi.mif 5tt.mif wmt_lmax${LMAXS}.txt gmt_lmax${LMAXS}.txt csf_lmax${LMAXS}.txt -mask mask.mif -lmax ${LMAXS} -tempdir ./tmp -force -nthreads $NCORE
			echo "Estimating MSMT CSD FOD of Lmax ${LMAXS}"
			time dwi2fod msmt_csd dwi.mif wmt_lmax${LMAXS}.txt wmt_lmax${LMAXS}_fod.mif  gmt_lmax${LMAXS}.txt gmt_lmax${LMAXS}_fod.mif csf_lmax${LMAXS}.txt csf_lmax${LMAXS}_fod.mif -force -nthreads $NCORE
		fi
		# convert to niftis
		mrconvert wmt_lmax${LMAXS}_fod.mif -stride 1,2,3,4 ./csd/lmax${LMAXS}.nii.gz -force -nthreads $NCORE
	
		# copy response file
		if [[ ${LMAXS} == ${lmax} ]]; then
			cp wmt_lmax${LMAXS}.txt response.txt
		fi
	else
		echo "csd already inputted. skipping csd generation"
		cp -v ${input_csd} ./csd/lmax${LMAXS}.nii.gz
	fi
done

# far periphery
echo "${track}"
for (( i_lmax=2; i_lmax<=$max_lmax; i_lmax+=2 )); do
        for curv in ${Curv}; do
		for step in ${Step}; do
                	if [ ! -f track_${track}_${i_lmax}_${curv}_${step}.tck ]; then
                	        # Run trekker
                	        echo "running tracking on lmax ${i_lmax} curv ${curv} step ${step} with Trekker"
                	        /trekker/build/bin/trekker \
                	                -enableOutputOverwrite \
                	                -fod ./csd/lmax${i_lmax}.nii.gz \
                	                -seed_image ${ROI1} \
                	                -pathway_A=stop_at_exit ${ROI1} \
					-pathway_A=discard_if_enters exclusion.nii.gz \
                	                -pathway_A=discard_if_enters csf_bin.nii.gz \
					-pathway_B=require_entry wm_bin.nii.gz \
					-pathway_B=require_exit wm_bin.nii.gz \
                	                -pathway_B=require_entry ${track_roi}.nii.gz \
					-pathway_B=require_entry thalLatPostDwi.nii.gz \
                	                -pathway_B=discard_if_enters exclusion.nii.gz \
					-pathway_B=discard_if_enters csf_bin.nii.gz \
					-pathway_B=stop_at_exit ${track_roi}.nii.gz \
                	                -stepSize ${step} \
                	                -minRadiusOfCurvature ${curv} \
                	                -probeRadius ${probe_radius} \
                	                -probeLength ${probe_length} \
                	                -minLength ${min_length} \
                	                -maxLength ${max_length} \
                	                -seed_countPerVoxel ${count} \
                	                -seed_maxTrials ${seedmaxtrials} \
                	                -maxSamplingPerStep ${maxsampling} \
                	                -minFODamp ${min_fod_amp} \
                	                -writeColors \
                	                -verboseLevel 0 \
					-output track_${track_roi}_${i_lmax}_${curv}_${step}.vtk \
                	                -numberOfThreads $NCORE \
					-timeLimit 10 \
					-useBestAtInit

                	        # convert output vtk to tck
                	        tckconvert track_${track_roi}_${i_lmax}_${curv}_${step}.vtk track_${track_roi}_${i_lmax}_${curv}_${step}.tck -force -nthreads $NCORE
                	fi
		done
        done
done

holder=(*track_${track_roi}*.tck)
tckedit ${holder[*]} ./track/track.tck


#cleanup
mv *track_E*.tck *.nii.gz *.mif *.gii ./raw/

# periphery
#echo "${periph_roi}"
#for (( i_lmax=2; i_lmax<=$max_lmax; i_lmax+=2 )); do
#        for Periph_curv in 0.25 0.5 0.75 1 2; do
#		for step in 0.025 0.05 0.1 0.15 0.2 0.25; do
#                	if [ ! -f track_${periph_roi}_${i_lmax}_${Periph_curv}.tck ]; then
#                	        # Run trekker
#                	        echo "running tracking on lmax ${i_lmax} curv ${Periph_curv} step ${step} with Trekker"
#                	        /trekker/build/bin/trekker \
#                	                -enableOutputOverwrite \
#                	                -fod ./csd/lmax${i_lmax}.nii.gz \
#                	                -seed_image ${ROI1} \
#                	                -pathway_A=stop_at_exit ${ROI1} \
#					-pathway_A=discard_if_enters exclusion.nii.gz \
#                	                -pathway_A=discard_if_enters csf_bin.nii.gz \
#					-pathway_B=require_entry wm_bin.nii.gz \
#					-pathway_B=require_exit wm_bin.nii.gz \
#                	                -pathway_B=require_entry ${periph_roi}.nii.gz \
#					-pathway_B=require_entry thalLatPostDwi.nii.gz \
#                	                -pathway_B=discard_if_enters exclusion.nii.gz \
#					-pathway_B=discard_if_enters csf_bin.nii.gz \
#					-pathway_B=stop_at_exit ${periph_roi}.nii.gz \
#                	                -stepSize ${step} \
#                	                -minRadiusOfCurvature ${Periph_curv} \
#                	                -probeRadius ${probe_radius} \
#                	                -probeLength ${probe_length} \
#                	                -minLength ${min_length} \
#                	                -maxLength ${max_length} \
#                	                -seed_countPerVoxel ${count} \
#                	                -seed_maxTrials ${seedmaxtrials} \
#                	                -maxSamplingPerStep ${maxsampling} \
#                	                -minFODamp ${min_fod_amp} \
#                	                -writeColors \
#                	                -verboseLevel 0 \
#					-output track_${periph_roi}_${i_lmax}_${Periph_curv}_${step}.vtk \
#                	                -numberOfThreads $NCORE \
#					-timeLimit 10 \
#                	                -useBestAtInit
#
#                	        # convert output vtk to tck
#                	        tckconvert track_${periph_roi}_${i_lmax}_${Periph_curv}_${step}.vtk track_${periph_roi}_${i_lmax}_${Periph_curv}_${step}.tck -force -nthreads $NCORE
#                	fi
#		done
#        done
#done
#
#holder=(*track_${periph_roi}*.tck)
#tckedit ${holder[*]} ./track_${periph_roi}.tck
#
## macular
#echo "${mac_roi}"
#for (( i_lmax=2; i_lmax<=$max_lmax; i_lmax+=2 )); do
#        for Mac_curv in 0.5 1 2 3 4; do
#		for step in 0.025 0.05 0.1 0.15 0.2 0.25; do
#                	if [ ! -f track_${mac_roi}_${i_lmax}_${Mac_curv}.tck ]; then
#                	        # Run trekker
#                	        echo "running tracking on lmax ${i_lmax} with Trekker"
#                	        /trekker/build/bin/trekker \
#                	                -enableOutputOverwrite \
#                	                -fod ./csd/lmax${i_lmax}.nii.gz \
#                	                -seed_image ${ROI1} \
#                	                -pathway_A=stop_at_exit ${ROI1} \
#					-pathway_A=discard_if_enters exclusion.nii.gz \
#                	                -pathway_A=discard_if_enters csf_bin.nii.gz \
#					-pathway_B=require_entry wm_bin.nii.gz \
#					-pathway_B=require_exit wm_bin.nii.gz \
#                	                -pathway_B=require_entry ${mac_roi}.nii.gz \
#					-pathway_B=require_entry thalLatPostDwi.nii.gz \
#                	                -pathway_B=discard_if_enters exclusion.nii.gz \
#					-pathway_B=discard_if_enters csf_bin.nii.gz \
#                	                -pathway_B=stop_at_exit ${mac_roi}.nii.gz \
#                	                -stepSize ${step} \
#                	                -minRadiusOfCurvature ${Mac_curv} \
#                	                -probeRadius ${probe_radius} \
#                	                -probeLength ${probe_length} \
#                	                -minLength ${min_length} \
#                	                -maxLength ${max_length} \
#                	                -seed_countPerVoxel ${count} \
#                	                -seed_maxTrials ${seedmaxtrials} \
#                	                -maxSamplingPerStep ${maxsampling} \
#                	                -minFODamp ${min_fod_amp} \
#                	                -writeColors \
#                	                -verboseLevel 0 \
#					-output track_${mac_roi}_${i_lmax}_${Mac_curv}_${step}.vtk \
#                	                -numberOfThreads $NCORE \
#					-timeLimit 10 \
#                	                -useBestAtInit
#
#                	        # convert output vtk to tck
#                	        tckconvert track_${mac_roi}_${i_lmax}_${Mac_curv}_${step}.vtk track_${mac_roi}_${i_lmax}_${Mac_curv}_${step}.tck -force -nthreads $NCORE
#                	fi
#        done
#done
#
#holder=(*track_${mac_roi}*.tck)
#tckedit ${holder[*]} ./track_${mac_roi}.tck

## concatenate tracts
#holder=(track_${farperiph_roi}.tck track_${periph_roi}.tck track_${mac_roi}.tck)
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
#       rm -rf *.mif *.b* ./tmp *.vtk* *track*.json
#else
#       echo "tracking failed"
#       exit 1;
#fi
