function [minBound, maxBound] = findBoundsDE(financialGoals, totalLoad, newTechs)

maxLoad = max(totalLoad);
maxBound = zeros(size(newTechs));
minBound = zeros(size(newTechs));
maxBound(1:15) = (newTechs(1:15) == 1) .* ceil(maxLoad * 1.2);


%% Tank
if (newTechs(16) == 1)
    maxBound(16) = ceil(prctile(movsum(totalLoad, 168), 100));
end



end