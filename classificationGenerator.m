function [] = classificationGenerator()

if ~isdeployed
    disp('loading path')
    addpath(genpath('/N/u/hayashis/git/vistasoft'))
    addpath(genpath('/N/u/brlife/git/jsonlab'))
    addpath(genpath('/N/u/brlife/git/wma_tools'))
end

% Load configuration file
config = loadjson('config.json')
%roiPair = strtrim(config.roiPair)

% Set tck file path/s
disp('merging tcks')
tcks=dir('track*.tck')
for ii = 1:length(tcks); 
    fgPath{ii} = tcks(ii).name;
end
disp(fgPath)
[mergedFG, classification]=bsc_mergeFGandClass(fgPath);

if ~exist('wmc', 'dir')
    mkdir('wmc')
end
if ~exist('wmc/tracts', 'dir')
    mkdir('wmc/tracts')
end

% Amend name of tract in classification structure
%roiPair = split(roiPair);
%for ii = 1:length(roiPair)
%    classification.names{ii} = strcat('ROI_',roiPair{ii},'_ROI_v1');
%end
save('wmc/classification.mat','classification')

% split up fg again to create tracts.json
fg_classified = bsc_makeFGsFromClassification_v4(classification,mergedFG);
tracts = fg2Array(fg_classified);
%cm = parula(length(tracts));
cm = distinguishable_colors(length(tracts));
for it = 1:length(tracts)
   tract.name   = strrep(tracts{it}.name, '_', ' ');
   all_tracts(it).name = strrep(tracts{it}.name, '_', ' ');
   all_tracts(it).color = cm(it,:);
   tract.color  = cm(it,:);

   %tract.coords = tracts(it).fibers;
   %pick randomly up to 1000 fibers (pick all if there are less than 1000)
   fiber_count = length(tracts{it}.fibers);
   tract.coords = tracts{it}.fibers; 
   
   savejson('', tract, fullfile('wmc','tracts', sprintf('%i.json',it)));
   all_tracts(it).filename = sprintf('%i.json',it);
   clear tract
end

% Save json outputs
savejson('', all_tracts, fullfile('wmc/tracts/tracts.json'));

% Create and write output_fibercounts.txt file
for ii = 1 : length(fg_classified)
    name = fg_classified{ii}.name;
    num_fibers = length(fg_classified{ii}.fibers);
    
    fibercounts(ii) = num_fibers;
    tract_info{ii,1} = name;
    tract_info{ii,2} = num_fibers;
end

T = cell2table(tract_info);
T.Properties.VariableNames = {'Tracts', 'FiberCount'};

writetable(T, fullfile('wmc','output_fibercounts.txt'));

exit;
end

