function [] = generatePlaneROI()

if ~isdeployed
    disp('loading path')

    %for IU HPC
    addpath(genpath('/N/u/hayashis/git/vistasoft'))
    addpath(genpath('/N/u/brlife/git/encode'))
    addpath(genpath('/N/u/brlife/git/jsonlab'))
    addpath(genpath('/N/u/brlife/git/spm'))
    addpath(genpath('/N/u/bacaron/git/wma_tools'))

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

% load lgn roi so we can extract thalamus
lgn = bsc_loadAndParseROI(fullfile(rois,sprintf('ROI%s.nii.gz',lgn_seed)));
referenceNifti = fullfile(rois,sprintf('ROI%s.nii.gz',lgn_seed));

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

end


