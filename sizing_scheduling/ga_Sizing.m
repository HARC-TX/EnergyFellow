function [BestChrom, cgcurve, uniqueGene] = ga_Sizing(Problem, M, MaxGen, Pc, Pm, Er,...
    PV, PL, HL, T_amb, financialGoals,tech_data,state_tech)
global parallel
log_function('Initialize sizing', 'debug')
cgcurve = zeros(1, MaxGen+1);
geneMapCurve = zeros(1, MaxGen+1);
geneMapCurve(1) = M;

%% Initialization of different technologies
[ population ] = gaPopgeneration(M, Problem.lb, Problem.ub);
newPopulation = population;

%% Calculation of fitness values for each gene
if parallel == 1
    for k = 1:M
        [population(k).fitness, ~, population(k).powerCost, ~]...
            = Problem.obj(population(k).Gene, PV, PL, HL,T_amb, financialGoals,tech_data,state_tech);
    end
else
    parfor k = 1:M
        [population(k).fitness, ~, population(k).powerCost, ~]...
            = Problem.obj(population(k).Gene, PV, PL, HL,T_amb, financialGoals,tech_data,state_tech);
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
    log_function(['Start sizing generation #', num2str(g)], 'debug')
    for k = 1:2:M 
        %% Selection
        [parent1_idx, parent2_idx] = gaSelectionSizing([population.fitness]);
        
        %% Crossover
        [child1, child2] = gaCrossoverSizing(population(parent1_idx).Gene, ...
            population(parent2_idx).Gene, Pc, 'single');
        
        %% Mutation
        child1 = gaMutationSizing(child1, Pm, Problem);
        child2 = gaMutationSizing(child2, Pm, Problem);
        newPopulation(k).Gene = child1;
        newPopulation(k+1).Gene = child2;
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
                    = Problem.obj(newPopulation(k).Gene, PV, PL, HL,T_amb, financialGoals,tech_data,state_tech);
                totalGeneMap(strjoin(string(newPopulation(k).Gene), ',')) = newPopulation(k).fitness;
            end
        end
    else
        parfor k = 1:M
            if isempty(newPopulation(k).fitness)
                [newPopulation(k).fitness, ~, newPopulation(k).powerCost, ~]...
                    = Problem.obj(newPopulation(k).Gene, PV, PL, HL,T_amb, financialGoals,tech_data,state_tech);
            end
        end
        for k = 1:M
            totalGeneMap(strjoin(string(newPopulation(k).Gene), ',')) = newPopulation(k).fitness;
        end
    end
    
    %% Elitism
    [newPopulation] = gaElitismSizing(population, newPopulation, Er);
    
    %% trim elite population by removing unused technology
    for k = 1:round(M * Er)
        if isempty(newPopulation(k).powerCost)
            [newPopulation(k).fitness, ~, newPopulation(k).powerCost,  ~]...
                = Problem.obj(newPopulation(k).Gene, PV, PL, HL,T_amb, financialGoals,tech_data,state_tech);
        end
        % check if there's any unused tech in elite gene
        if any(xor(newPopulation(k).Gene([3:9,12]), newPopulation(k).powerCost([3:9,12])))
            % reduce unused tech by 1 step size
            [~, step] = gaPopSparse(newPopulation(k).Gene, Problem.lb, Problem.ub);
            newPopulation(k).Gene = newPopulation(k).Gene - step .* ...
                ([0,0,ones(1,9),0] & (newPopulation(k).powerCost == 0) ...
                & (newPopulation(k).Gene >= step));
            % remove battery & TES if solar & CHPs not exist or no resilience requirements
            newPopulation(k).Gene(10:11) = newPopulation(k).Gene(10:11) .* ...
                (([sum(newPopulation(k).Gene(1:2)), sum(newPopulation(k).Gene(3:5))] > 0) | ...
                (financialGoals.resilienceGoalTime & financialGoals.resilienceGoalLoad));
            if isKey(totalGeneMap, {strjoin(string(newPopulation(k).Gene), ',')})
                newPopulation(k).fitness = cell2mat(values(totalGeneMap, {strjoin(string(newPopulation(k).Gene), ',')}));
            else
                [newPopulation(k).fitness, ~, newPopulation(k).powerCost, ~]...
                    = Problem.obj(newPopulation(k).Gene, PV, PL, HL,T_amb, financialGoals,tech_data,state_tech);
                totalGeneMap(strjoin(string(newPopulation(k).Gene), ',')) = newPopulation(k).fitness;
            end
        end
    end
    
    %% Finish current generation
    population = newPopulation;
    all_fitness_values = [population(:).fitness];
    [cgcurve(g+1), ~] = max(all_fitness_values );
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
    BestChrom(i).state_vector = (population(bestChromIdx(i)).Gene > 0);
    BestChrom(i).optimal_size = population(bestChromIdx(i)).Gene;
    
    [BestChrom(i).npv,BestChrom(i).power_generated, BestChrom(i).power_cost, BestChrom(i).annualFuel, cf]...
            = Problem.obj(BestChrom(i).optimal_size, PV, PL, HL,T_amb, financialGoals,tech_data,state_tech);

    BestChrom(i).power_load = PL;
    BestChrom(i).thermal_load = HL;
    
    BestChrom(i).cash_flow = cf.cashFlow;
    
    BestChrom(i).capital_cost =  cf.fixedCost;
    BestChrom(i).operation_cost = cf.operationCost;
    BestChrom(i).maintenance_cost = cf.maintenanceCost;
    BestChrom(i).salvage_cost =  cf.salvageCost;
    BestChrom(i).replacement_cost = cf.replacementCost;
    BestChrom(i).detailCost = cf.detailCost;
end

end