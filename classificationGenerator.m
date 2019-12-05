function [] = classificationGenerator()

if ~isdeployed
    disp('loading path')

    %for IU HPC
    addpath(genpath('/N/u/brlife/git/vistasoft'))
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

% Set tck (fg) file path/s
trackdir = dir(fullfile('track','*.tck*'));
for ii = 1:length(trackdir); 
    fgPath{ii} = fullfile(topdir,'track',trackdir(ii).name);
end

% set seed ROI number: should be 8109 or 8209 for now
roiNum = str2num(config.seed_roi);

%% Create whole OR fg_classified structure to feed into eccentricity
[mergedFG, whole_classification]=bsc_mergeFGandClass(fgPath);

% THINK OF BETTER HIEURISTIC FOR THIS. NOT ALL LGNS WILL HAVE THIS ROI NUM
if roiNum == 8109
	hemi = 'left';
    whole_classification.names = {'left-optic-radiation'};
else
    hemi = 'right';
	whole_classification.names = {'right-optic-radiation'};
end

% whole OR tractogram
wbFG = mergedFG;

% whole OR fg_classified

whole_fg_classified = bsc_makeFGsFromClassification_v4(whole_classification,wbFG);
[clean_classification] = cleanFibers(whole_classification,mergedFG,hemi);

%% perform eccentricity classification
[fg_classified,classification] = eccentricityClassification(config,whole_fg_classified,wbFG,clean_classification,hemi);

%% Save output
save('output.mat','classification','fg_classified','-v7.3');

%% create tracts for json structures for visualization
tracts = fg2Array(fg_classified);

mkdir('tracts');

% Make colors for the tracts
%cm = parula(length(tracts));
cm = distinguishable_colors(length(tracts));
for it = 1:length(tracts)
   tract.name   = strrep(tracts{it}.name, '_', ' ');
   all_tracts(it).name = strrep(tracts{it}.name, '_', ' ');
   all_tracts(it).color = cm(it,:);
   tract.color  = cm(it,:);

   %tract.coords = tracts(it).fibers;
   %pick randomly up to 1000 fibers (pick all if there are less than 1000)
   fiber_count = min(1000, numel(tracts{it}.fibers));
   tract.coords = tracts{it}.fibers(randperm(fiber_count)); 
   
   savejson('', tract, fullfile('tracts',sprintf('%i.json',it)));
   all_tracts(it).filename = sprintf('%i.json',it);
   clear tract
end

% Save json outputs
savejson('', all_tracts, fullfile('tracts/tracts.json'));

% Create and write output_fibercounts.txt file
for i = 1 : length(fg_classified)
    name = fg_classified{i}.name;
    num_fibers = length(fg_classified{i}.fibers);
    
    fibercounts(i) = num_fibers;
    tract_info{i,1} = name;
    tract_info{i,2} = num_fibers;
end

T = cell2table(tract_info);
T.Properties.VariableNames = {'Tracts', 'FiberCount'};

writetable(T, 'output_fibercounts.txt');

exit;
end
