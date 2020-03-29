#!/bin/bash

#set -x

## This script uses AFNI's (Taylor PA, Saad ZS (2013).  FATCAT: (An Efficient) Functional And Tractographic Connectivity Analysis Toolbox. Brain 
## Connectivity 3(5):523-535. https://afni.nimh.nih.gov/) 3dROIMaker function to a) remove the white matter mask from the cortical segmentation 
## inputted (i.e. freesurfer or parcellation; BE CAREFUL: REMOVES SUBCORTICAL ROIS) and b) inflates the ROIs by n voxels into the white matter 
## based on user input (option for no inflation is also built in). The output of this will then passed into a matlab function (roiGeneration.m) to 
## create nifti's for each ROI requested by the user, which can then be fed into a ROI to ROI tracking app (brainlife.io; www.github.com/brain-life/
## app-roi2roitracking).

ROI=Ecc30to90.nii.gz
inflate=3
brainmask=`jq -r '.brainmask' config.json`

l1="-skel_stop -trim_off_wm";

echo "${inflate} voxel inflation applied to every cortical label in parcellation";
l4="-inflate ${inflate} -prefix ${ROI::-7}";


# inflate visual areas
3dROIMaker \
	-inset ${ROI} \
	-refset ${ROI} \
	-mask ${brainmask} \
	-wm_skel /home/brad/Desktop/app-roiGenerator/wm_anat.nii.gz \
	-skel_thr 0.5 \
	-skel_stop \
	${l4} \
	-nifti \
	-overwrite;

#generate rois
#PRFROIS=`echo ${prfROIs} | cut -d',' --output-delimiter=$'\n' -f1-`
#
#for VIS in ${PRFROIS}
#do
#        3dcalc -a visarea_inflate_GMI.nii.gz -expr 'equals(a,'${VIS}')' -prefix ROI000${VIS}.nii.gz
#done
#
