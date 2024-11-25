function population = gaPopDE(M, nbus, pd, dist, demand, minBound, maxBound, tempDiff)
k = 0;
nPipes = size(pd,1);

population = struct();
while k < M
    selectBuilding = [1, randi(2, 1, nbus - 1)-1]; % make sure central plant is selected
    tempDemand = max(sum(demand(:, (selectBuilding(2:end))>0), 2));
    if sum(selectBuilding) > 2 && tempDemand > 1% at least 2 buildings are selected
            temp = tspSolver(find(selectBuilding), dist(:, 1:3));
            templength = sum(dist(temp > 0, 3));
            minPipe = findMinPipe(templength, pd, tempDemand, tempDiff);
            temp = temp * randi([minPipe,nPipes]);
        tempMaxBound = min(maxBound, tempDemand * 1.2);
        tempMaxBound(16) = maxBound(16);
        tempGene = randomPopulation(minBound, tempMaxBound);
        % make sure the random population contians enough power
        while sum(tempGene(1:15)) < tempDemand * 1.2
            tempGene = randomPopulation(minBound, tempMaxBound);
        end
        k = k + 1;
        population(k).Gene = [tempGene, temp];
    end
end

end

function sparseGene = randomPopulation(minBound, maxBound)
gene = zeros(1, length(maxBound));
for i = 1:length(maxBound)
    gene(i) = randi([minBound(i), round(maxBound(i) *1.1)],1);
end
sparseGene = gaPopSparse(gene, minBound, maxBound);
end