function newGene = gaReviseDE(gene, pd, dist, demand, supplyTemperature, returnTemperature)
% nPipes = size(pd,1);
newGene = gene;
conduitType = mean(nonzeros(gene(17:end)));
if conduitType < size(pd,1)
    selectBuilding = getBuilding(gene(17:end),0);
    tempDemand = max(sum(demand(:, (selectBuilding-1)), 2));
    tempLength = sum(dist(gene(17:end) > 0, 3));
    minPipe = findMinPipe(tempLength, pd, tempDemand, supplyTemperature - returnTemperature);
    % in case none of the pipe sizes can satisfy the flow velocity / pressure loss
    minPipe(isempty(minPipe)) = size(pd,1); 
    newGene(17:end) = (gene(17:end) > 0) .* minPipe;
end

end