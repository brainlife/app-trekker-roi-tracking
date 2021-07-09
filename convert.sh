#!/bin/bash

roiPair=`jq -r '.roiPair' config.json`

pairs=($roiPair)
range=` expr ${#pairs[@]}`
nTracts=` expr ${range} / 2` 

for (( i=0; i<${nTracts}; i++ )); do
	holder=(*track$((i+1))*)

	for tractograms in ${holder[*]}; do
		tckconvert ${tractograms} ${tractograms::-4}.tck
	done
	
	tcks=(*track$((i+1))*.tck)
	output=track$((i+1)).tck

	if [ ${#tcks[@]} == 1 ]; then
		mv ${tcks[0]} ${output}
	else
		tckedit ${tcks[*]} $output
		mv ${tcks[*]} ./raw/
	fi
	tckinfo $output > track$((i+1))_info.txt
done

if [ -f track1.tck ]; then
	mv *.mif *.vtk *.b* *.nii.gz ./raw/
	holder=(track*.tck)
	if [ ${#holder[@]} == 1 ]; then
        cp -v ${holder[0]} ./track/track.tck
    else
        tckedit ${holder[*]} ./track/track.tck
    fi
	tckinfo ./track/track.tck > ./track/track_info.txt
else
    echo "tracking did not generate. please check derivatives and log files for debugging"
    exit 1
fi	
