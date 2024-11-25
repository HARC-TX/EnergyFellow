function [BestChrom, cgcurve, uniqueGene] = gaDistrictCooling ...
    (M, MaxGen, Pc, Pm, Er, minBound, maxBound, ...
        nbus,dist,BuildingLoad,weather,pd, financialGoals, newTechs)
global parallel
log_function('Initialize district energy', 'debug')
cgcurve = zeros(1, MaxGen+1);
geneMapCurve = zeros(1, MaxGen+1);
geneMapCurve(1) = M;

%% Initialization
[ population ] = gaPopDE(M, nbus, pd, dist, BuildingLoad, minBound, maxBound, financialGoals.supplyTemperature - financialGoals.returnTemperature);
newPopulation = population;

%% Calculation of fitness values for each gene
if parallel == 1
    for k = 1:M
        [population(k).fitness, ~, population(k).powerCost, ~]...
            = fitnessDE(population(k).Gene, BuildingLoad, nbus,dist,pd, weather, financialGoals);
        
    end
else
    parfor k = 1:M
        [population(k).fitness, ~, population(k).powerCost, ~]...
            = fitnessDE(population(k).Gene, BuildingLoad, nbus,dist,pd, weather, financialGoals);
    end
end

all_fitness_values = [population(:).fitness];
[cgcurve(1), ~] = max(all_fitness_values);

totalGeneMap = containers.Map('KeyType','char','ValueType','double');
for k = 1:M
    totalGeneMap(strjoin(string(population(k).Gene), ',')) = population(k).fitness;
end
%% Main Loop
for g = 1:MaxGen
    log_function(['Start district energy generation #', num2str(g)], 'debug')
    for k = 1:2:M 
        %% Selection
        [parent1_idx, parent2_idx] = gaSelectionDE([population.fitness]);
        
        %% Crossover
        [child1, child2] = gaCrossoverDE(population(parent1_idx).Gene, ...
            population(parent2_idx).Gene, Pc, 'single');
        
        %% Mutation
        child1 = gaMutationDE(child1, minBound, maxBound, nbus, dist, BuildingLoad, size(pd,1), Pm);
        child2 = gaMutationDE(child2, minBound, maxBound, nbus, dist, BuildingLoad, size(pd,1), Pm);
        newPopulation(k).Gene = gaReviseDE(child1, pd, dist, BuildingLoad, financialGoals.supplyTemperature, financialGoals.returnTemperature);
        newPopulation(k+1).Gene = gaReviseDE(child2, pd, dist, BuildingLoad, financialGoals.supplyTemperature, financialGoals.returnTemperature);
    end
    
    %% Fill in values with existing gene
    for k = 1:M
        if isKey(totalGeneMap, {strjoin(string(newPopulation(k).Gene), ',')})
            newPopulation(k).fitness = cell2mat(values(totalGeneMap, ...
                {strjoin(string(newPopulation(k).Gene), ',')}));
            newPopulation(k).powerCost = [];
        else
            newPopulation(k).fitness = [];
        end
    end
    
    %% Calculate fitness value for new gene    
    if parallel == 1
        for k = 1:M
            if isempty(newPopulation(k).fitness)
                [newPopulation(k).fitness, ~, newPopulation(k).powerCost, ~]...
                    = fitnessDE(newPopulation(k).Gene, BuildingLoad, nbus,dist,pd, weather, financialGoals);
                totalGeneMap(strjoin(string(newPopulation(k).Gene), ',')) = newPopulation(k).fitness;
            end
        end
    else
        parfor k = 1:M
            if isempty(newPopulation(k).fitness)
                [newPopulation(k).fitness, ~, newPopulation(k).powerCost, ~]...
                    = fitnessDE(newPopulation(k).Gene, BuildingLoad, nbus,dist,pd, weather, financialGoals);
            end
        end
        for k = 1:M
            totalGeneMap(strjoin(string(newPopulation(k).Gene), ',')) = newPopulation(k).fitness;
        end
    end
    
    %% Elitism
    [newPopulation] = gaElitismDE(population, newPopulation, Er);
    %% Finish current generation
    population = newPopulation;
    all_fitness_values = [population(:).fitness];
    [cgcurve(g+1), ~] = max(all_fitness_values );
    geneMapCurve(g+1) = size(totalGeneMap, 1);
    %% skip generation
    if g > 10 && all([diff(geneMapCurve((g-3) :g)) < M * 0.618, ...
            diff(cgcurve(g+(-9:1))) == 0])
        log_function(sprintf('terminate at generation #%i, after analyzed %i gene', g, geneMapCurve(g + 1)), 'info')
        %break
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
    % BestChrom(i).state_vector = (population(bestChromIdx(i)).Gene > 0);
    BestChrom(i).Gene = population(bestChromIdx(i)).Gene;
    
    [BestChrom(i).npv,BestChrom(i).schedule , BestChrom(i).powerCost, ...
        BestChrom(i).sittingCashFlow, BestChrom(i).sizingCashFlow, BestChrom(i).techData]...
            = fitnessDE(BestChrom(i).Gene, BuildingLoad, nbus,dist,pd, weather, financialGoals);
end

end