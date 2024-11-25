function [annualOpCost, techOpCost, annualFuel, Sch, lifeCycle, techMaintCost] = costOperation(N, PV, P, thermal_load, T_amb, financialGoals)
global skipMode

%% initial variables
fminconMaxAttempts = 30;
totalHours = length(P);
techNums = length(N);
Sch = zeros(totalHours,10);
techMaintCost = zeros(1,techNums);
schBoiler = zeros(totalHours,1);
remainder = zeros(totalHours,1);
opCost = zeros(totalHours,techNums);
PV_GB = PV' .* N(1);
PV_RT = PV' .* N(2);
lifeCycle = zeros(techNums,1);
netP = P -  PV_GB - PV_RT; 

%% skipMode
if strcmpi(skipMode, "true")
    computationLength = 60;
else
    computationLength = 8760;
end
%% calculate minimum tank & battery state to fullfill resilience
[~, maxThermalBuilding] = max(sum(thermal_load));
battMin = zeros(totalHours,1);
tankMin = zeros(totalHours,1);
if financialGoals.resilienceGoalTime >= 1 && financialGoals.resilienceGoalLoad > 0
%     if N(6) > 0
        resilienceDemand = [netP; netP(1:financialGoals.resilienceGoalTime-1)]...
            * financialGoals.resilienceGoalLoad / 100;
        resilienceDemand(resilienceDemand > 0) = max(resilienceDemand(resilienceDemand > 0) - sum(N([3 4 5 6 7 8 9])), 0);
        auxBattMin = movsum(resilienceDemand,...
            [0 financialGoals.resilienceGoalTime-1],'Endpoints','discard');
        resilienceDemand(resilienceDemand < 0) = 0;
        battMin = movsum(resilienceDemand,...
            [0 financialGoals.resilienceGoalTime-1],'Endpoints','discard');
        battMin(auxBattMin < 0 & netP < 0) = 0;
        % panelty for insufficient battery size
        techMaintCost(10) = sum(battMin(battMin > N(10)) - N(10)) ...
            * financialGoals.electricityPrice * 1000;
        battMin(battMin > N(10)) = N(10);
%     end
%     if N(7) > 0
        resilienceThermal = max([thermal_load(:, maxThermalBuilding);...
            thermal_load(1:financialGoals.resilienceGoalTime-1, maxThermalBuilding)]...
            * financialGoals.resilienceGoalLoad / 100 - CHPthermal(N(3),"NG") - CHPthermal(N(4),"H2") - CHPthermal(N(5),"BM"), 0);
        tankMin = movsum(resilienceThermal,...
            [0 financialGoals.resilienceGoalTime-1],'Endpoints','discard');
        % panelty for insufficient thermal storage size
        techMaintCost(11) = sum(tankMin(tankMin > N(11)) - N(11)) ...
            / financialGoals.boilerEfficiency(maxThermalBuilding) ...
             * financialGoals.naturalGasPrice *1000;
        tankMin(tankMin > N(11)) = N(11);
%     end
end
battMin(battMin < N(10) * 0.2) = N(10) * 0.2; % make sure battary never discharge below 20%
if sum(N([3,4,5,6,7,8,9,12])) == 0
    % solar + battery only
    batt = [max(battMin(end), min(-sum(netP), N(6))); zeros(totalHours,1)];
else
    batt = [battMin(end); zeros(totalHours,1)];
end
tank = [tankMin(end); zeros(totalHours,1)];
%% fuel consumption per kwh for NGCHP, H2CHP, BMCHP, NG, DG, H2G, BMG
fuelNGCHP = min(4.8143 .*N(3) .^-0.08, 10000); % kWh of NG per kWh
NGCHPThermalCredit = min(CHPthermal(N(3), "NG") / N(3) / financialGoals.boilerEfficiency(maxThermalBuilding), 10000);

fuelH2CHP = 2.83313 ./ 42.55157; % 42.55157 kwh/kg of hydrogen
standbyFuelH2CHP = 32.1699 ./ 42.55157;
H2CHPThermalCredit = min(CHPthermal(N(4), "H2") / N(4) / financialGoals.boilerEfficiency(maxThermalBuilding), 100);

fuelBMCHP = min(0.4229*N(5)^-0.08, 100);
BMCHPThermalCredit = min(CHPthermal(N(5), "BM") / N(5) / financialGoals.boilerEfficiency(maxThermalBuilding), 100);

[fuelNG, standbyFuelNG] = NatureGasGenerator(N(6));

fuelDG = 0.19; % avg L/kwh

fuelH2G = 2.8331 ./ 42.55157; % 42.55157 kwh/kg of hydrogen
standbyFuelH2G = 32.17 ./ 42.55157;

%% fuel cost
load utilityPriceData;
%% natural gas price
% get natural gas consumption for each building (col) & every month (row)
naturalGasMonthly = cell2mat(cellfun(@sum, split2monthly(thermal_load), 'UniformOutput', false)')';

if max(sum(naturalGasMonthly, 1)) > 43960
    naturalGasPrice = utilityPriceData.naturalGas.industrial.hourlyPrice ...
        + utilityPriceData.naturalGas.industrial.hourlyFixedPrice;
    naturalGasOther = utilityPriceData.naturalGas.industrial.annuallyPrice;
else
    naturalGasPrice = utilityPriceData.naturalGas.commercial.hourlyPrice ...
        + utilityPriceData.naturalGas.commercial.hourlyFixedPrice;
    naturalGasOther = utilityPriceData.naturalGas.commercial.annuallyPrice;
end
%% hydrogen price
h2LoadAssumption = min(max(0, netP), N(4) + N(8));
[hydrogenPrice, h2MTPD] = getH2Price(h2LoadAssumption .* fuelH2CHP, "green");

fuelBMG = 0.19; % PENDING
%% grid price
% get max electricity demand for every month
electricityMonthlyMax = cellfun(@max, split2monthly(netP));

if max(electricityMonthlyMax) > 1000
    utilityPrice = utilityPriceData.electricity.industrial;
else
    utilityPrice = utilityPriceData.electricity.commercial;
end

monthlyCapPrice = electricityMonthlyMax .* utilityPrice.capacityPrice;
hourlyCapPrice = cell2mat(cellfun(@times, split2monthly(ones(8760,1)), ...
    num2cell(monthlyCapPrice ./ cellfun(@sum, split2monthly(max(0, netP)))), 'UniformOutput', false)');
priceGrid = utilityPrice.hourlyPrice + utilityPrice.hourlyFixedPrice + hourlyCapPrice;

%% utility price scaling
if financialGoals.electricityPriceInput == "true"
    priceGrid = priceGrid .* financialGoals.electricityPrice / mean(priceGrid);
end
if financialGoals.naturalGasPriceInput == "true"
    naturalGasPrice = naturalGasPrice .* financialGoals.naturalGasPrice / mean(naturalGasPrice);
end
if financialGoals.hydrogenPriceInput == "true"
    hydrogenPrice = hydrogenPrice .* financialGoals.hydrogenPrice / mean(hydrogenPrice);
end

%% maintenance cost per kwh for NGCHP, H2CHP, BMCHP, NG, DG, H2G, BMG
maintNGCHP = 1e-10*N(3)^2-3e-6*N(5)+0.0232;
maintH2CHP = (1e-10*N(4)^2-3e-6*N(5)+0.0232) .* 1.15; % 15% higher than normal CHP as per Doug Edgar
maintNG = min(0.2822*N(6)^(-0.315), 100);
maintDG = min(0.6497*N(7)^(-0.478), 100);
maintH2G = min(0.2822*N(6)^(-0.315) * 1.15, 100); % 15% higher than normal CHP

unitCost = [zeros(8760,2), (fuelNGCHP - NGCHPThermalCredit) .* naturalGasPrice + maintNGCHP, ...
    (fuelH2CHP .* hydrogenPrice - H2CHPThermalCredit .* naturalGasPrice) + maintH2CHP, ...
    (fuelBMCHP .* financialGoals.biomassPrice .* ones(8760,1) - BMCHPThermalCredit .* naturalGasPrice), ...
    fuelNG .* naturalGasPrice + maintNG, ...
    fuelDG .* financialGoals.dieselPrice .* ones(8760,1) + maintDG, ...
    fuelH2G .* hydrogenPrice + maintH2G, ...
    fuelBMG .* financialGoals.biomassPrice .* ones(8760,1), ...
    zeros(8760,2), priceGrid];
unitCost(unitCost > 100) = 100;
unitCost(isnan(unitCost)) = 100;
%% degradation
CHPdegradation = 1 - (T_amb > 25) .* ((T_amb - 25) .* 0.0025);
NGDGdegradation = 1 - (T_amb > 40) .* ((T_amb - 40) .* 0.006);
degradation = [CHPdegradation, CHPdegradation, CHPdegradation, NGDGdegradation, NGDGdegradation, NGDGdegradation, NGDGdegradation];

%% greedy algorithm
unitCostGreedy = unitCost(:, [3,4,5,6,7,8,9,12]) ./ (N([3,4,5,6,7,8,9,12]) > 0) ./ [degradation, ones(8760,1)];
for t = 1:computationLength
    [Sch(t,:), schBoiler(t), batt(t + 1), tank(t + 1), remainder(t), fminconMaxAttempts]...
        = scheduler(N .* [1,1, degradation(t, :), 1,1,1], netP(t), thermal_load(t, maxThermalBuilding), batt(t),...
        battMin(t), tank(t), tankMin(t), unitCostGreedy(t,:), fminconMaxAttempts);
end

%% calculate fuel consumption for NGCHP, H2CHP, BMCHP, NG, DG, H2G, BMG, battery, TES, grid
% in unit of 
% kwh(NG), kg(h2), kwh(DUMP), kwh(NG), l(diesel), kg(h2), kwh(DUMP), kwh, kwh, kwh
fuelConsumption = Sch ./ [degradation, ones(8760,3)] ...
    .* [fuelNGCHP, fuelH2CHP, ...
    fuelBMCHP, ...
    fuelNG, fuelDG, fuelH2G, fuelBMG, 0, 0, 1];
fuelConsumption(:,2) = fuelConsumption(:,2) + (Sch(:,2) > 0) * standbyFuelH2CHP;
fuelConsumption(:,4) = fuelConsumption(:,4) + (Sch(:,4) > 0) * standbyFuelNG;
fuelConsumption(:,5) = fuelConsumption(:,5) + (Sch(:,5) > 0) * 5 ; % averaged from 3 DG
fuelConsumption(:,6) = fuelConsumption(:,6) + (Sch(:,6) > 0) * standbyFuelH2G;
annualFuel = sum(fuelConsumption, 1);

%% calculate fuel cost
[hydrogenPriceActual, h2MTPDActual] = getH2Price(fuelConsumption(:,2) + fuelConsumption(:,6), "green");

hourlyCapPriceActual = cell2mat(cellfun(@times, split2monthly(Sch(:, 10) > 0), num2cell(monthlyCapPrice ./ cellfun(@sum, split2monthly(Sch(:,10)))), 'UniformOutput', false)');
if any(isnan(hourlyCapPriceActual))
    hourlyCapPriceActual(isnan(hourlyCapPriceActual)) = hourlyCapPrice(isnan(hourlyCapPriceActual));
end
electricityPriceActual = utilityPrice.hourlyPrice + utilityPrice.hourlyFixedPrice + hourlyCapPriceActual;

%% utility price scaling
if financialGoals.electricityPriceInput == "true"
    electricityPriceActual = electricityPriceActual .* financialGoals.electricityPrice / mean(electricityPriceActual);
end
if financialGoals.hydrogenPriceInput == "true"
    hydrogenPriceActual = hydrogenPriceActual .* financialGoals.hydrogenPrice / mean(hydrogenPriceActual);
end

fuelCost = fuelConsumption .* [naturalGasPrice, hydrogenPriceActual, ...
    financialGoals.biomassPrice .* ones(8760,1), naturalGasPrice, ...
    financialGoals.dieselPrice .* ones(8760,1), hydrogenPriceActual, ...
    financialGoals.biomassPrice .* ones(8760,1), zeros(8760,2), electricityPriceActual];
thermalCredit = [Sch(:, [1 2 3]) .* [NGCHPThermalCredit, H2CHPThermalCredit, ...
    BMCHPThermalCredit] .* naturalGasPrice, zeros(8760,7)];

%cost(:,3) = cost(:,3) + (Sch(:,3) > 0) * standbyFueCHP;
maintCost = Sch(:, 1:7) .* [maintNGCHP, maintH2CHP, maintNGCHP, maintNG, maintDG, maintH2G, maintNG];
Sch(:, 8) = diff(batt);
Sch(:, 9) = diff(tank);
batt = batt(2:totalHours+1);
tank = tank(2:totalHours+1);
%% calculate operation cost for each technology
opCost(:, 3:12) = fuelCost - thermalCredit;

%% penalty for infeasible schedule
idx = find(remainder > 0);
%[idx,P(idx),Sch(idx,:),remainder(idx)]
opCost(idx, 12) = netP(idx) * financialGoals.electricityPrice * 1000;
%%
Sch = [PV_GB, PV_RT, Sch];

annualOpCost = sum(opCost, 'all');
techOpCost = sum(opCost);
techMaintCost(3:9) = sum(maintCost);
for i = 1:length(lifeCycle)
    lifeCycle(i) = nnz(Sch(:,i));        % Runtime of units PV_GB, PV_RT, NGCHP, H2CHP, BMCHP, NG, DG, H2G, BMG, Grid
end

end