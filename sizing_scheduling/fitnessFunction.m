function [NPV, Sch, opCost, annualFuel, cf] = fitnessFunction(N, PV, P, H, T_amb, financialGoals,tech_data,~)

D = financialGoals.lifespan;
techFixedCost = costFixed(N, tech_data);
[annualOpCost, opCost, annualFuel, Sch, lifeCycle, techMaintCost] = costOperation(N, PV, P, H, T_amb, financialGoals);
maintenanceCost = costMaintenance(N);
[cfReplacement, ~] = costReplacement(techFixedCost * 0.6, tech_data.replacement_cost1, D, lifeCycle);
salvageCost = costSalvage(techFixedCost * 0.6, tech_data.replacement_cost1, D, lifeCycle);

cfFixed = [-sum(techFixedCost), zeros(1,D)];
cfOperation = [0, -ones(1,D) * annualOpCost];
cfMaintenance = [0, -ones(1,D) * sum(maintenanceCost + techMaintCost)];

cfSalvage = [zeros(1,D), sum(salvageCost)];


CF = cfFixed + cfOperation + cfMaintenance + sum(cfReplacement(:,1:end)) + cfSalvage;

cf.cashFlow = CF;
cf.fixedCost = cfFixed;
cf.operationCost = cfOperation;
cf.maintenanceCost = cfMaintenance;
cf.replacementCost = sum(cfReplacement);
cf.salvageCost = cfSalvage;
cf.detailCost = -[techFixedCost; maintenanceCost + techMaintCost; opCost];

NPV = pvvar(CF, financialGoals.interestRate);

end