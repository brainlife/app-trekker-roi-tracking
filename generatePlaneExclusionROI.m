function [] = generatePlaneExclusionROI()

if ~isdeployed
    disp('loading path')

    %for IU HPC
    addpath(genpath('/N/u/hayashis/git/vistasoft'))
    addpath(genpath('/N/u/brlife/git/encode'))
    addpath(genpath('/N/u/brlife/git/jsonlab'))
    addpath(genpath('/N/u/brlife/git/spm'))
    addpath(genpath('/N/u/brlife/git/wma_tools'))

    %for old VM
    addpath(genpath('/usr/local/vistasoft'))
    addpath(genpath('/usr/local/encode'))
    addpath(genpath('/usr/local/jsonlab'))
    addpath(genpath('/usr/local/spm'))
    addpath(genpath('/usr/local/wma_tools'))
end

% Set top directory
topdir = pwd;

% Load configuration file
config = loadjson('config.json');
lgn_seed = config.seed_roi;
rois = config.rois;
fsurf = config.freesurfer;

% load lgn roi so we can extract thalamus
lgn = bsc_loadAndParseROI(fullfile(rois,sprintf('ROI%s.nii.gz',lgn_seed)));
referenceNifti = fullfile(config.anat);

% load stuff for exclusion ROI
referenceParc = fullfile('aparc.a2009s.aseg.nii.gz');

% set exclusion ROIS
%if str2num(lgn_seed) == 8109
%    exclusionRoiLUT = [41 42 7 8 4];
%else
%    exclusionRoiLUT = [2 3 46 47 43];
%end

%% Generate plane ROI for forced tracking to get loop
% Planar ROI
% define posterior limit coords
posteriorThalLimit = bsc_planeFromROI_v2([lgn],'posterior',referenceNifti);

% define lateral limit coords
lateralThalLimit = bsc_planeFromROI_v2([lgn],'lateral',referenceNifti);

% generate lateral posterior plane of thalamus to capture loop
thalLatPost = bsc_modifyROI_v2(referenceNifti,lateralThalLimit,posteriorThalLimit,'anterior');

% save ROI as nifti
[~,~] = dtiRoiNiftiFromMat(thalLatPost,referenceNifti,'thalLatPost.nii.gz',true);

%% genereate exclusion ROI
% define exclusion coords
%exclusionROI = bsc_roiFromAtlasNums(referenceParc,[exclusionRoiLUT ],1);
%
%% save as nifti
%[~,~] = dtiRoiNiftiFromMat(exclusionROI,referenceParc,'exclusion.nii.gz',true);

end


