function [newPopulation2] = ga_elitism(population, newPopulation, Er)

M = length(newPopulation);  % Number of individuals
Elite_no = round(M*Er);

[max_val, idx] = sort([population(:).fitness], 'descend');

for k = 1:Elite_no
    
    newPopulation2(k).Gene = population(idx(k)).Gene;
    newPopulation2(k).fitness = population(idx(k)).fitness;
    
end

[max_val, idx] = sort([newPopulation(:).fitness], 'descend');

for k = 1: length(population) - Elite_no
    newPopulation2(k+Elite_no).Gene = newPopulation(idx(k)).Gene;
    newPopulation2(k+Elite_no).fitness = newPopulation(idx(k)).fitness;
end

end