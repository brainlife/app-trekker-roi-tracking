#!/bin/bash

roiPair=`jq -r '.roiPair' config.json`

pairs=($roiPair)
range=` expr ${#pairs[@]}`
nTracts=` expr ${range} /2` 

for (( i=1; i<=$nTracts; i+=1 )); do
	holder=(*track$((i))*)

	for tractograms in ${holder[*]}; do
		tckconvert ${tractograms} ${tractograms::-4}.tck
	done
	
	tcks=(*track$((i))*.tck)
	output=track$((i)).tck

	if [ ${#tcks[@]} == 1 ]; then
		mv ${tcks[0]} ${output}
	else
		tckedit ${tcks[*]} $output
		mv ${tcks[*]} ./raw/
	fi
	tckinfo $output > track$((i))_info.txt
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
