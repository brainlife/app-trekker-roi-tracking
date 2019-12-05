function [fg_classified,classification] = eccentricityClassification(config,whole_fg_classified,wbFG,clean_classification,hemi)

% parse arguments
MinDegree = [str2num(config.MinDegree)];
MaxDegree = [str2num(config.MaxDegree)];

for dd = 1:length(MinDegree)
    eccen.(sprintf('Ecc%sto%s',num2str(MinDegree(dd)),num2str(MaxDegree(dd)))) = ...
        bsc_loadAndParseROI(fullfile(sprintf('Ecc%sto%s.nii.gz',num2str(MinDegree(dd)),num2str(MaxDegree(dd)))));
end

% need to edit this for loop for multiple tracts in classification (i.e.
% both left and right hemisphere OR, or OT and OR, etc). currently works
% with one tract at a time
for ifg = 1:length(whole_fg_classified)
    for dd = 1:length(MinDegree)
        [~, keep.(sprintf('Ecc%sto%s',num2str(MinDegree(dd)),num2str(MaxDegree(dd))))] = ...
            wma_SegmentFascicleFromConnectome(whole_fg_classified{ifg}, ...
            [{eccen.(sprintf('Ecc%sto%s',num2str(MinDegree(dd)),num2str(MaxDegree(dd))))} ],...
            {'endpoints' }, 'dud');
        keep.(sprintf('Ecc%sto%s',num2str(MinDegree(dd)),num2str(MaxDegree(dd)))) = ...
            keep.(sprintf('Ecc%sto%s',num2str(MinDegree(dd)),num2str(MaxDegree(dd)))) * dd;
    end
end

index_pre = [keep.(sprintf('Ecc%sto%s',num2str(MinDegree(1)),num2str(MaxDegree(1)))) ...
    keep.(sprintf('Ecc%sto%s',num2str(MinDegree(2)),num2str(MaxDegree(2)))) ...
    keep.(sprintf('Ecc%sto%s',num2str(MinDegree(3)),num2str(MaxDegree(3))))];

for ii = 1:length(index_pre)
    if isequal(median(index_pre(ii,:)),0)
        index(ii) = max(index_pre(ii,:));
    elseif isequal(median(index_pre(ii,:)),2) && isequal(min(index_pre(ii,:)),1)
        index(ii) = min(index_pre(ii,:));
    elseif isequal(median(index_pre(ii,:)),2) || isequal(median(index_pre(ii,:)),1)
        index(ii) = median(index_pre(ii,:));
    end
end

classification.index = clean_classification.index.*index';
% create new classification structure
classification.names = {'macular','periphery','far_periphery'};
fg_classified = bsc_makeFGsFromClassification_v4(classification,wbFG);
end
