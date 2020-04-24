addpath(genpath('/N/u/brlife/git/vistasoft'))
addpath(genpath('/N/u/brlife/git/jsonlab'))
addpath(genpath('/N/u/brlife/git/encode'))
addpath(genpath('/N/u/brlife/git/spm'))
addpath(genpath('/N/u/hayashis/git/vistasoft'))
mcc -m -R -nodisplay -d compiled classificationGenerator
mcc -m -R -nodisplay -d planeExclusionROI generatePlaneExclusionROI
exit
