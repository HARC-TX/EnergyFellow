function [npv,Sch, opCost, sittingCF, sizingCF, techData] = fitnessDE(gene, load,nbus,dist,pd, weather,financialGoals)
% fitness function for distrct energy

lifespan = financialGoals.lifespan;
thermalStorageCostVolume = gene(16) / abs(financialGoals.tankFullTemp - financialGoals.tankEmptyTemp);
selectBuilding = getBuilding(gene(17:end), nbus);
%% calculate sitting cost
conduitType = mean(nonzeros(gene(17:end)));
conduitFixedCost = sum(dist(gene(17:end) > 0, 3) * pd{conduitType, 'installation'});
conduitMaint = sum(dist(gene(17:end) > 0, 3) * pd{conduitType, 'maintenance'});
conduitLoss = unitConduitLoss(weather, financialGoals, financialGoals.supplyTemperature, ...
    financialGoals.returnTemperature, pd(conduitType,:)) .* sum(dist(gene(17:end) > 0, 3));

totalLoad = (sum(load(:, (selectBuilding-1)),2) + conduitLoss ...
    .* ((financialGoals.supplyTemperature > financialGoals.returnTemperature)*2-1));
[hydraulicPower, techData.flowVelocity, techData.totalPressureLoss] ...
    = pressureLoss(pd(conduitType,:).innerRadius, totalLoad, ...
    abs(financialGoals.supplyTemperature - financialGoals.returnTemperature), sum(dist(gene(17:end) > 0, 3)));
pumpLoad = hydraulicPower ./ 0.9 .* 1.1;
techData.pumpLoad = pumpLoad;
pumpMaintCost = interp1([1, 10, 100, 500, 500*10], [17.5, 175, 700, 3500, 3500*10], max(pumpLoad) * 1.1 / 0.7457, 'makima');
pumpFixedCost = interp1([1, 10, 100, 500, 500*10], [875, 8750, 35000, 175000, 175000*10], max(pumpLoad) * 1.1 / 0.7457, 'makima');

%% calculate sizing cost
[electricityCost, fuelCost, electricityConsumption, fuelConsumption, Sch, ...
    lifeCycle, techMaintCost, electricityPriceActual, HWCHPSize] = costOperationDE( ...
    gene(1:16), totalLoad, weather, financialGoals);

[install(1:3), maint(1:3)] = hotWaterChillerCost(gene(1:3)); % PENDING
CHPCostF = costFixed([0, 0, [CHPelectric(HWCHPSize(1) + gene(9),"NG"), ...
    CHPelectric(HWCHPSize(2) + gene(10),"H2"), CHPelectric(HWCHPSize(3) + gene(11),"BM")], zeros(1,7)]);
install(9:11) = CHPCostF(3:5);

[install(4:6), maint(4:6)] = naturalGasChillerCost(gene(4:6));
install(5) = install(5) * 1.18; % H2 fired chiller fixed cost is 18% higher than NG fired chiller

[install(7), maint(7)] = airElectricChillerCost(gene(7));
[install(8), maint(8)] = waterElectricChillerCost(gene(8));

[install(12:14), maint(12:14)] = naturalGasBoilerCost(gene(12:14));
install(13) = install(13) * 1.18; % H2 boiler fixed cost is 18% higher than NG boiler

[install(15), maint(15)] = electricityBoilerCost(gene(15));
[install(16), maint(16)] = thermalStorageCost(thermalStorageCostVolume * 50);

opCost = sum([electricityCost, fuelCost]);
maint(9:11) = techMaintCost(9:11);
centralPlantFixedCost = sum(install);
centralPlantMaintCost = sum(maint);
techData.fuelConsumption = fuelConsumption;
techData.electricityConsumption = electricityConsumption;
pumpOperationCost = pumpLoad .* electricityPriceActual;
%%
sittingCF.capital_cost = [(-conduitFixedCost - pumpFixedCost), zeros(1, lifespan)];
sittingCF.maintenance_cost = [0, -ones(1, lifespan)] .* (conduitMaint + pumpMaintCost);
sittingCF.replacement_cost = [0, ones(1, lifespan)] .* sittingCF.capital_cost(1) .* 0.01;
sittingCF.salvage_cost = [zeros(1, lifespan), 1] .* (conduitFixedCost) .* 0.1;

sittingCF.cash_flow = sittingCF.capital_cost + sittingCF.maintenance_cost + sittingCF.replacement_cost + sittingCF.salvage_cost;

sizingCF.capital_cost = [(-centralPlantFixedCost), zeros(1, lifespan)];
sizingCF.maintenance_cost = [0, -ones(1, lifespan)] .* (centralPlantMaintCost + sum(techMaintCost));
sizingCF.operation_cost = -sum(opCost) - sum(pumpOperationCost);
sizingCF.replacement_cost = [0, ones(1, lifespan)] .* sizingCF.capital_cost(1) .* 0.01;
sizingCF.salvage_cost = [zeros(1, lifespan), 1] .* (centralPlantFixedCost) .* 0.1;

sizingCF.cash_flow = sizingCF.capital_cost + sizingCF.maintenance_cost + [0, ones(1, lifespan)] .* sizingCF.operation_cost + sizingCF.replacement_cost + sizingCF.salvage_cost;
sizingCF.detailCost = -[install; maint; sum(reshape(opCost', [16,2])',1)];

npv = pvvar(sittingCF.cash_flow + sizingCF.cash_flow, financialGoals.interestRate);
end