function population = gaPopgeneration(M, minBound, maxBound)
k = 0;
while k < M
    tempGene = randomPopulation(minBound, maxBound);
    % make sure the random population contians enough power
    if sum(tempGene([3,4,5,8])) + sum(tempGene(1:2)) / 2 >= max(maxBound([3,4,5,8]))
        k = k + 1;
        population(k).Gene = tempGene;
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