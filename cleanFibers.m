function classification = cleanFibers(whole_classification,mergedFG)

% generate new, empty classification structure
classification = whole_classification;
clean_sd = [4,3];

% remove streamlines based on cleaning criteria
for ifg = 1:length(whole_classification.names)
    for sd = 1:length(clean_sd)
        classification = removeOutliersClassification(classification,mergedFG,clean_sd(sd),4,5);
    end
end