function [BestChrom, cgcurve] = gaAssignParam(minBound,maxBound, PV, PL, HL,...
    T_amb, financialGoals, tech_data, ga_data,state_tech)

%% Control parameters of the GA

Problem.obj = @fitnessFunction;
Problem.nVar = length(maxBound);

Problem.lb = ones(1, Problem.nVar).* minBound;
Problem.ub = ones(1, Problem.nVar).* maxBound;

M = ga_data(1,2);  % number of chromosomes (candidate solutions)
N = Problem.nVar;   % number of genes (variables)
MaxGen = ga_data(2,2);
Pc = ga_data(3,2);
Pm = ga_data(4,2);
Er = ga_data(5,2);

%% Calling the main Genetic Algorithm
[BestChrom, cgcurve] = ga_Sizing(Problem, M, MaxGen, Pc, Pm, Er, PV, PL, HL, T_amb, financialGoals,tech_data,state_tech);


end