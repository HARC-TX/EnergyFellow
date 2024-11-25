function [sit_result, population,Optimum, cgcurve, uniqueGene] = siting(nbus, dist,...
    power_load, financialGoals, LinesData, ga_data)

%% Control parameters of the GA
Problem.obj = @cost_function;
Problem.nVar = (size(dist,1) - 1);

numCables = size(LinesData(:,1),1);

M = ga_data(1,1);  % number of chromosomes (candidate solutions)
maxGen = ga_data(2,1);
Pc = ga_data(3,1);  % Crossover rate
Pm = ga_data(4,1);  % Mutation rate
Er = ga_data(5,1);  % Elitism rate

noSolarDist = dist(dist(:,2) > 0,:);
%% Calling the main Genetic Algorithm
if maxGen > 0 && M > 4 
    [population,Optimum, cgcurve, uniqueGene] = gaSiting(Problem.obj, M, maxGen, Pc, Pm,...
        Er, nbus, numCables, noSolarDist(:, 1:3), power_load, financialGoals, LinesData);
elseif (maxGen <= 0 || M <= 4) && sum(noSolarDist(:,4)) <= 0
    M = 20;
    maxGen = 2;
    [population,Optimum, cgcurve, uniqueGene] = gaSiting(Problem.obj, M, maxGen, Pc, Pm,...
        Er, nbus, numCables, noSolarDist(:, 1:3), power_load, financialGoals, LinesData);
end
%% Eveluate customized solution
if sum(noSolarDist(:,4)) > 0
    if exist('Optimum', 'var')
        Optimum(end+1).Gene = noSolarDist(:, 4)';
    else
        Optimum(1).Gene = noSolarDist(:, 4)';
        population = struct;
        cgcurve = 0;
        uniqueGene = 1;
    end
    [Optimum(end).fitness, Optimum(end).PGen, Optimum(end).cashFlows]...
        = cost_function(noSolarDist(:, 4), noSolarDist(:, 1:3), power_load, financialGoals, LinesData, nbus);
end

for i = 1:length(Optimum)
    temp = Optimum(i).cashFlows;
    temp.topology = Optimum(i).Gene;
    temp.npv_val = Optimum(i).fitness;
    sit_result(i)= temp;
end

end