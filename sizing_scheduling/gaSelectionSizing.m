function [parent1_idx, parent2_idx] = gaSelectionSizing(fitness)

M = length(fitness);

if ~all(fitness - fitness(1))
    normalized_fitness = [ones(1, M - 1), 0] / (M - 1);
else
    Scaled_fitness = fitness - min(fitness);
    normalized_fitness = Scaled_fitness ./ sum(Scaled_fitness);
end

[sorted_fitness_values, sorted_idx] = sort(normalized_fitness , 'descend');

cumsumFitness = cumsum(sorted_fitness_values, 'reverse');

R = rand(); % in (0,1)
parent1_sorted_idx = find(R > cumsumFitness, 1) - 1;

R = rand();
parent2_sorted_idx = find(R > cumsumFitness, 1) - 1;

if parent1_sorted_idx == parent2_sorted_idx
    parent2_sorted_idx = M;
end

parent1_idx = find(parent1_sorted_idx == sorted_idx, 1);
parent2_idx = find(parent2_sorted_idx == sorted_idx, 1);

end

