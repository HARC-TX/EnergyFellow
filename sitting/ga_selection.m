function [parent1, parent2] = ga_selection(population)

M = length(population(:));

if any([population(:).fitness] < 0 ) 
    % Fitness scaling in case of negative values scaled(f) = a * f + b
    a = 1;
    b = abs( min(  [population(:).fitness] )  );
    Scaled_fitness = a *  [population(:).fitness] + b;
    
    normalized_fitness = [Scaled_fitness] ./ sum([Scaled_fitness]);
else
    normalized_fitness = [population(:).fitness] ./ sum([population(:).fitness]);
end


[sorted_fintness_values , sorted_idx] = sort(normalized_fitness , 'descend');

for i = 1 : length(population)
    temp_population(i).Gene = population(sorted_idx(i)).Gene;
    temp_population(i).fitness = population(sorted_idx(i)).fitness;
    temp_population(i).normalized_fitness = normalized_fitness(sorted_idx(i));
end


cumsum = zeros(1 , M);

for i = 1 : M
    for j = i : M
        cumsum(i) = cumsum(i) + temp_population(j).normalized_fitness;
    end
end


R = rand(); % in [0,1]
parent1_idx = M;
for i = 1: length(cumsum)
    if R > cumsum(i)
        parent1_idx = i - 1;
        break;
    end
end

parent2_idx = parent1_idx;
while_loop_stop = 0; % to break the while loop in rare cases where we keep getting the same index
while parent2_idx == parent1_idx
    while_loop_stop = while_loop_stop + 1;
    R = rand(); % in [0,1]
    if while_loop_stop > 20
        break;
    end
    for i = 1: length(cumsum)
        if R > cumsum(i)
            parent2_idx = i - 1;
            break;
        end
    end
end

parent1 = temp_population(parent1_idx);
parent2 = temp_population(parent2_idx);

end

