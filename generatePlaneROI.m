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
roiPair = split(config.roiPair);
rois = config.rois;

% load lgn roi so we can extract thalamus
for ii = 1:length(roiPair)
    display(roiPair{ii})
    
    lgn = bsc_loadAndParseROI(fullfile(rois,sprintf('ROI%s.nii.gz',roiPair{ii})));
    referenceNifti = fullfile(rois,sprintf('ROI%s.nii.gz',roiPair{ii}));

    %% Generate plane ROI for forced tracking to get loop
    % Planar ROI
    % define posterior limit coords
    posteriorThalLimit = bsc_planeFromROI_v2_brad([lgn],'posterior',referenceNifti);

    % define anterior limit coords
    anteriorThalLimit = bsc_planeFromROI_v2_brad([lgn],'anterior',referenceNifti);
    
    % find difference between posterior and anterior, subtract .25 of difference from anterior limit to get rid of streamline going straight down
    midantcoords = anteriorThalLimit.coords;
    coords_diff = (midantcoords(1,2) - posteriorThalLimit.coords(1,2));
    midantcoords(:,2) = (midantcoords(:,2) - (coords_diff * .75));
    posteriorThalLimitCropped = posteriorThalLimit;
    posteriorThalLimitCropped.coords = midantcoords;
	
    % define lateral limit coords
    lateralThalLimit = bsc_planeFromROI_v2_brad([lgn],'lateral',referenceNifti);
    
    % define medial limit coords
    medialThalLimit = bsc_planeFromROI_v2_brad([lgn],'medial',referenceNifti);

    % generate lateral posterior plane of thalamus to capture loop
    thalLatPost = bsc_modifyROI_v2(referenceNifti,lateralThalLimit,posteriorThalLimitCropped,'anterior');

    % generate medial posterior plane of thalamus to exclude incorrect loop
    thalMedPost = bsc_modifyROI_v2(referenceNifti,medialThalLimit,posteriorThalLimit,'anterior');

    % save ROIs as nifti
    [~,~] = dtiRoiNiftiFromMat_brad(thalLatPost,referenceNifti,sprintf('thalLatPost_%s.nii.gz',roiPair{ii}),true);
    [~,~] = dtiRoiNiftiFromMat_brad(thalMedPost,referenceNifti,sprintf('thalMedPost_%s.nii.gz',roiPair{ii}),true);

    % clear data
    clear lgn referenceNifti  posteriorThalLimit lateralThalLimit medialThalLimit thalLatPost thalMedPost midantcoords coords_diff posteriorThalLimitCropped
end
end

