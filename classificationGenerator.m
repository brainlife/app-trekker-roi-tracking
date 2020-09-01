function [] = classificationGenerator()

if ~isdeployed
    disp('loading path')
    %for IU HPC
    addpath(genpath('/N/u/hayashis/git/vistasoft'))
    addpath(genpath('/N/u/brlife/git/encode'))
    addpath(genpath('/N/u/brlife/git/jsonlab'))
    addpath(genpath('/N/u/brlife/git/spm'))
    addpath(genpath('/N/u/bacaron/git/wma_tools'))
    addpath(genpath('/N/u/brlife/git/mba'))

    %for old VM
    addpath(genpath('/usr/local/vistasoft'))
    addpath(genpath('/usr/local/encode'))
    addpath(genpath('/usr/local/jsonlab'))
    addpath(genpath('/usr/local/spm'))
    addpath(genpath('/usr/local/wma_tools'))
    addpath(gepnath('/usr/local/mba'))
end

% Set top directory
topdir = pwd;

% make wmc directory
if ~isdir(fullfile(topdir,'wmc'))
	mkdir(fullfile(topdir,'wmc'))
end

% Load configuration file
config = loadjson('config.json');

% Set tck (fg) file path/s
trackdir = dir(fullfile('*.tck*'));
for ii = 1:length(trackdir); 
    fgPath{ii} = fullfile(topdir,trackdir(ii).name);
end

%% Create classification and fg_classified
[mergedFG, whole_classification]=bsc_mergeFGandClass(fgPath);

% set classification names
% trackNames = split(config.names,' ');
% for ii = 1:length(whole_classification.names)
%     whole_classification.names{ii} = trackNames{ii};
% end

% OR tractogram
wbFG = mergedFG;

% clean fibers; removing for now (9/1/2020)
%classification = cleanFibers(whole_classification,wbFG);

% OR fg_classified
fg_classified = bsc_makeFGsFromClassification_v4(whole_classification,wbFG);

%% Save output
save(fullfile(topdir,'wmc','classification.mat'),'classification','fg_classified','-v7.3');

%% create tracts for json structures for visualization
tracts = fg2Array(fg_classified);

mkdir(fullfile(topdir,'wmc','tracts'));

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
   %fiber_count = min(1000, numel(tracts{it}.fibers));
   %tract.coords = tracts{it}.fibers(randperm(fiber_count)); 
   tract.coords = tracts{it}.fibers; 
   savejson('', tract, fullfile(topdir,'wmc','tracts',sprintf('%i.json',it)));
   all_tracts(it).filename = sprintf('%i.json',it);
   clear tract
end

% Save json outputs
savejson('', all_tracts, fullfile(topdir,'wmc','tracts/tracts.json'));

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

writetable(T, fullfile(topdir,'wmc','output_fibercounts.txt'));

exit;
end
