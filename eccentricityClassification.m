function [fg_classified,classification] = eccentricityClassification(config,whole_fg_classified,wbFG)

% parse arguments
eccentricity = niftiRead(fullfile(config.eccentricity));
out_ijk = eccentricity.qto_ijk;

% need to edit this for loop for multiple tracts in classification (i.e.
% both left and right hemisphere OR, or OT and OR, etc). currently works
% with one tract at a time
for ifg = 1:length(whole_fg_classified)
    fg = whole_fg_classified{ifg};
    fprintf('%s\n',fg.name);
    
    % convert to output space
    fg = dtiXformFiberCoords(fg, out_ijk, 'img');

    % initialize endpoint outputs
    iep = zeros(length(fg.fibers), 3);

    % for every fiber, pull the end points
    for ii = 1:length(fg.fibers)
        iep(ii,:) = fg.fibers{ii}(:,end)';
    end

    % combine fiber endpoints & round
    iepRound = round(iep)+1;
    ep = iepRound;

    % find eccentricity for endpoints
    for ii = 1:length(ep)
        ecc(ii) = eccentricity.data(ep(ii,1),ep(ii,2),ep(ii,3));
    end
    
    % create index for streamlines based on eccentricity critera: R1 = 0-3,
    % R2 = 15-30, R3 = 30-90
    for ii = 1:length(ecc)
        if ecc(ii) >= 0 && ecc(ii) < 5
            index(ii) = 1;
        elseif ecc(ii) >= 15 && ecc(ii) < 30
            index(ii) = 2;
        elseif ecc(ii) >= 30 && ecc(ii) <= 90
            index(ii) = 3;
        else
            index(ii) = 0;
        end
    end
end

% create new classification structure
classification.names = {'macular','periphery','far_periphery'};
classification.index = index';
fg_classified = bsc_makeFGsFromClassification_v4(classification,wbFG);

end