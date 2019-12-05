function [classification,mergedFG] = cleanFibers(whole_classification,mergedFG,hemi)


classification.names = whole_classification.names;
classification.index = [];

referenceNifti = niftiRead(fullfile('aparc.a2009s.aseg.nii.gz'));
%referenceNifti_lgn.left = niftiRead(fullfile(config.rois,'ROI008109.nii.gz'));
%referenceNifti_lgn.right = niftiRead(fullfile(config.rois,'ROI008209.nii.gz'));
%exclusionROIs.left = [41 42];
%exclusionROIs.right = [2 3];
exclusionROIs.left = [41 42 7 8 4 28];
exclusionROIs.right = [2 3 46 47 43 60];

thalLUT.left = [10];
thalLUT.right = [48];



%% Generate NOT ROIs
% CSF ROI
csfROI = bsc_loadAndParseROI('csf_bin.nii.gz');

% Planar ROI
% load reference nifti for planar ROI
if strcmp(hemi,'left')
    thal = bsc_roiFromAtlasNums(referenceNifti,[thalLUT.left ],1);
    posteriorThalLimit = bsc_planeFromROI_v2([thal],'posterior',referenceNifti);
    lateralThalLimit = bsc_planeFromROI_v2([thal],'lateral',referenceNifti);
    thalLatPost = bsc_modifyROI_v2(referenceNifti,lateralThalLimit,posteriorThalLimit,'anterior');
    hemisphereROI = bsc_roiFromAtlasNums(referenceNifti,[exclusionROIs.left ],1);
    %hemisphereROI = bsc_loadAndParseROI('ribbon_right.nii.gz');
else
    thal = bsc_roiFromAtlasNums(referenceNifti,[thalLUT.right ],1);
    posteriorThalLimit = bsc_planeFromROI_v2([thal],'posterior',referenceNifti);
    lateralThalLimit = bsc_planeFromROI_v2([thal],'lateral',referenceNifti);
    thalLatPost = bsc_modifyROI_v2(referenceNifti,lateralThalLimit,posteriorThalLimit,'anterior');
    hemisphereROI = bsc_roiFromAtlasNums(referenceNifti,[exclusionROIs.right ],1);
    %hemisphereROI = bsc_loadAndParseROI('ribbon_left.nii.gz');
end

% create not ROI
Not = bsc_mergeROIs(hemisphereROI,csfROI);

%% Load Optic radiations and clip for cleaning
% clip hemispheres and CSF for OR
for ifg = 1:length(whole_classification)
    tractFG.name = whole_classification.names{ifg};
    tractFG.colorRgb = mergedFG.colorRgb;
    display(sprintf('%s',tractFG.name))
    tractFG.fibers = mergedFG.fibers;
    [~, keep] = wma_SegmentFascicleFromConnectome(tractFG, [{Not} {thalLatPost} ], {'not','and' }, ['dud']);
    % set indices of streamlines that intersect the not ROI to 0 as if they
    % have never been classified
    classification.index = keep;
end
