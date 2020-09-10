#!/bin/bash

roiPair=`jq -r '.roiPair' config.json`
minDegree=`jq -r '.min_degree' config.json`
maxDegree=`jq -r '.max_degree' config.json`

minDegree=($minDegree)
maxDegree=($maxDegree)

for DEG in ${!minDegree[@]}; do
	holder=(track_Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}*.vtk)
	echo ${holder[*]}

	for tractograms in ${holder[*]}; do
		tckconvert ${tractograms} ${tractograms::-4}.tck
	done
	
	tcks=(track_Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}*.tck)
	output=track_Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.tck

	if [ ${#tcks[@]} == 1 ]; then
		mv ${tcks[0]} ${output}
	else
		tckedit ${tcks[*]} $output
		mv ${tcks[*]} ./raw/
	fi
	tckinfo $output > track_Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}_info.txt
done

if [ -f track_Ecc${minDegree[$DEG]}to${maxDegree[$DEG]}.tck ]; then
	mv *.mif *.vtk *.b* *.nii.gz *.func.gii ./raw/
	holder=(track*.tck)
	if [ ${#holder[@]} == 1 ]; then
        cp -v ${holder[0]} ./track/track.tck
    else
        tckedit ${holder[*]} ./track/track.tck
    fi
	tckinfo ./track/track.tck > ./track/track_info.txt
else
    echo "tracking did not generate. please check derivatives and log files for debugging"
    #exit 1
fi	