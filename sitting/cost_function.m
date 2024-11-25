function [NPV, PGen, cf] = cost_function(X, dist, power_load,...
    financialGoals, LinesData, nbus)
life_project = financialGoals.lifespan;
voltage = 20; %in KV

[fixedCost, costLC, costSubs] = cost_fixed(LinesData,X, dist(:,3), power_load);
maintenanceCost = cost_maintenance(LinesData,X, dist(:,3), power_load);
[lossCost,  PGen]= cost_powerloss(LinesData, X, dist, power_load, ...
    financialGoals.electricityPrice, nbus, voltage);
[cfReplacement, salvageCost] = cost_replacement_salvage(LinesData, X, ...
    dist(:,3), power_load, life_project) ;    

cfFixed = [-fixedCost, zeros(1, life_project)];
cfMaintenance = [0, -ones(1, life_project) * maintenanceCost];
cfPowerLoss = [0, -ones(1, life_project) * lossCost];
cfSalvage = [zeros(1, life_project), sum(salvageCost)];

CF = cfFixed + cfMaintenance + cfPowerLoss  + sum(cfReplacement) + cfSalvage;

cf.cash_flow = CF;
cf.capital_cost = cfFixed;
cf.maintenance_cost = cfMaintenance;
cf.power_loss_cost = cfPowerLoss;
cf.replacement_cost = sum(cfReplacement);
cf.salvage_cost = cfSalvage;

NPV = pvvar(CF, financialGoals.interestRate);
end