function [population, BestChrom, cgcurve, uniqueGene] = gaSiting(ObjF, M, MaxGen, Pc, Pm,...
    Er, nbus, numCables, dist, power_load, financialGoals, LinesData)
global parallel
log_function('Initialize sitting', 'debug')
cgcurve = zeros(1, MaxGen+1);
geneMapCurve = zeros(1, MaxGen+1);
geneMapCurve(1) = M;

%% Initialization
[ population , m ] = gaInitialization(nbus, numCables, M);
newPopulation = population;

%% Calculation of fitness values for initial values
if parallel == 1
    for k = 1:m
        [population(k).fitness, ~]...
            = ObjF(population(k).Gene(:), dist, power_load, financialGoals, LinesData, nbus);
    end
else
    parfor k = 1:M
        [population(k).fitness, ~]...
            = ObjF(population(k).Gene(:), dist, power_load, financialGoals, LinesData, nbus);
    end
end

all_fitness_values = [population(:).fitness];
[cgcurve(1), ~] = max(all_fitness_values );

totalGeneMap = containers.Map('KeyType','char','ValueType','double');
for k = 1:M
    totalGeneMap(strjoin(string(population(k).Gene), ',')) = population(k).fitness;
end
%% Main Loop
for g = 1:MaxGen
    log_function(['Start sitting generation #', num2str(g)], 'debug')
    for k = 1:2:m
        %% Selection
        [parent1, parent2] = ga_selection(population);
        
        %% Crossover
        crossoverName = 'single';
        [child1, child2] = ga_crossover(parent1.Gene, parent2.Gene, Pc, crossoverName);
        
        %% Mutation
        child1 = ga_mutation(child1, numCables, Pm);
        child2 = ga_mutation(child2, numCables, Pm);
        if isLegitConnection(child1, nbus)
            newPopulation(k).Gene = child1;
        end
        if isLegitConnection(child2, nbus)
            newPopulation(k+1).Gene = child2;
        end
    end
    %% Fill in values with existing gene

    for k = 1:M
        if isKey(totalGeneMap, {strjoin(string(newPopulation(k).Gene), ',')})
            newPopulation(k).fitness = cell2mat(values(totalGeneMap, ...
                {strjoin(string(newPopulation(k).Gene), ',')}));
        else
            newPopulation(k).fitness = [];
        end
    end
    
    %% Calculate fitness value for new gene
    if parallel == 1
        for k = 1:m
            if isempty(newPopulation(k).fitness)
                
                [newPopulation(k).fitness, ~]...
                    = ObjF(newPopulation(k).Gene(:), dist, power_load, financialGoals, LinesData, nbus);
                totalGeneMap(strjoin(string(newPopulation(k).Gene), ',')) = newPopulation(k).fitness;
            end
        end
    else
        parfor k = 1:M
            if isempty(newPopulation(k).fitness)
                [newPopulation(k).fitness, ~]...
                    = ObjF(newPopulation(k).Gene(:), dist, power_load, financialGoals, LinesData, nbus);
            end
        end
        for k = 1:M
            totalGeneMap(strjoin(string(newPopulation(k).Gene), ',')) = newPopulation(k).fitness;
        end
    end
    
    %% Elitism
    [newPopulation] = ga_elitism(population, newPopulation, Er);
    
    %% Finish current generation
    population = newPopulation;
    all_fitness_values = [population(:).fitness];
    [cgcurve(g+1), ~] = max(all_fitness_values);  
    geneMapCurve(g+1) = size(totalGeneMap, 1);
    %% skip generation
    if g > 10 && all([diff(geneMapCurve((g-3) :g)) < M * 0.618, ...
            diff(cgcurve(g+(-9:1))) == 0])
        log_function(sprintf('terminate at generation #%i, after analyzed %i gene', g, geneMapCurve(g + 1)), 'info')
        break
    end
end

uniqueGene = geneMapCurve(g + 1);
[max_val, idx] = sort([population(:).fitness], 'descend');

bestGeneMap = containers.Map('KeyType','char','ValueType','double');
bestGeneMap(strjoin(string(population(idx(1)).Gene), ',')) = idx(1);
bestChromIdx(1) = idx(1);
for k = 2:M
    if ~isKey(bestGeneMap, {strjoin(string(population(idx(k)).Gene), ',')})
        bestGeneMap(strjoin(string(population(idx(k)).Gene), ',')) = idx(k);
        bestChromIdx(end+1) = idx(k);
        if size(bestChromIdx,2) >= 5
            break
        end
    end
end

for i = 1:size(bestChromIdx,2)
    BestChrom(i).Gene = population(bestChromIdx(i)).Gene;
    [BestChrom(i).fitness, BestChrom(i).PGen, BestChrom(i).cashFlows] ...
        = ObjF(BestChrom(i).Gene(:), ...
        dist, power_load, financialGoals, LinesData, nbus);
end

end