#!/bin/bash
module load matlab/2017a

mkdir compiled planeROI

cat > build.m <<END
addpath(genpath('/N/u/bacaron/git/wma_tools'))
addpath(genpath('/N/u/brlife/git/jsonlab'))
addpath(genpath('/N/u/brlife/git/encode'))
addpath(genpath('/N/u/brlife/git/spm'))
addpath(genpath('/N/u/brlife/git/mba'))
addpath(genpath('/N/u/hayashis/git/vistasoft'))
mcc -m -R -nodisplay -d compiled classificationGenerator
exit
END
matlab -nodisplay -nosplash -r build
