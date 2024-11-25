function [electricityCost, fuelCost, electricityConsumption, fuelConsumption, ...
    Sch, lifeCycle, techMaintCost, electricityPriceActual, HWCHPSize] = costOperationDE(gene, demand, weather, financialGoals)
global skipMode

%% initial variables
fminconMaxAttempts = 0;
totalHours = length(demand);
techNums = 16;
Sch = zeros(totalHours,techNums);
HWCHPSize = [0, 0, 0];
remainder = zeros(totalHours,1);
lifeCycle = zeros(techNums,1);

T_amb = max(weather{:,6}, 19.44444); % chillers will remain same performance for temperature below 67F
humidityRelative = 1; % set relative humidity to 100%
T_wet = T_amb .* atan(0.1511977 .* (humidityRelative .* 100 + 8.313659) .^ 0.5) ...
    +atan(T_amb + humidityRelative .* 100) - atan(humidityRelative .* 100 - 1.676331) ...
    +atan(2.3101 .* humidityRelative) .* (3.91838 .* humidityRelative .^ (3/2)) - 4.686035;


%% skipMode
if strcmpi(skipMode, "true")
    computationLength = 60;
T_amb = ones(8760, 1) .* 37.77778;
T_wet = ones(8760, 1) .* 34.50525;
else
    computationLength = 8760;
end
%% calculate minimum tank & battery state to fullfill resilience
if financialGoals.resilienceGoalTime >= 1 && financialGoals.resilienceGoalLoad > 0
    tankMin = movsum([demand(:);...
        demand(1:financialGoals.resilienceGoalTime-1)],...
        [0 financialGoals.resilienceGoalTime-1],'Endpoints','discard')...
        * financialGoals.resilienceGoalLoad / 100;
    % panelty for insufficient thermal storage size
    techMaintCost(16) = sum(tankMin(tankMin > gene(16)) - gene(16)) * ...
        (1 / median(financialGoals.boilerEfficiency) * financialGoals.naturalGasPrice + ...
        1 / median(financialGoals.chillerEfficiency) * financialGoals.electricityPrice) *1000;
    tankMin(tankMin > gene(16)) = gene(16);
else
    tankMin = zeros(totalHours,1);
end
tank = [tankMin(end); zeros(totalHours,1)];
%% fuel consumption per kwh for NGHW, H2HW, BMHW, NG, H2, BM, EA, EW, NGCHP, H2CHP, BMCHP, NGB, H2B, BMB, EB
 %                            in kwh, kg, kwh, kwh, kg, kwh, kwh, kwh, kwh,  kg,    kwh,  kwh,  kg,  kwh, kwh 
load utilityPriceData;
% 
if financialGoals.systemType == "District Cooling"
    effiAssumption = mean(financialGoals.chillerEfficiency);
    h2Assumption = min(demand, gene(2) + gene(5)) ./ 42.55157; % assume avg H2 cop as 1
else
    effiAssumption = mean(financialGoals.boilerEfficiency);
    h2Assumption = min(demand, gene(10) + gene(13)) ./ 0.9 ./ 42.55157; % assume avg H2 efficiency as 0.9
end
naturalGasMonthly = cell2mat(cellfun(@sum, split2monthly(demand ./ effiAssumption), 'UniformOutput', false)')';

if max(sum(naturalGasMonthly, 1)) > 43960
    naturalGasPrice = utilityPriceData.naturalGas.industrial.hourlyPrice;
    naturalGasOther = utilityPriceData.naturalGas.industrial.annuallyPrice;
else
    naturalGasPrice = utilityPriceData.naturalGas.commercial.hourlyPrice;
    naturalGasOther = utilityPriceData.naturalGas.commercial.annuallyPrice;
end
%% hydrogen price

[hydrogenPrice, h2MTPD] = getH2Price(h2Assumption, "green");
%% grid price
electricityAssumption = min(demand, sum(gene([7,8,15]))) ./ effiAssumption;
% get max electricity demand for every month
electricityMonthlyMax = cellfun(@max, split2monthly(electricityAssumption));
if max(electricityMonthlyMax) / effiAssumption > 1000
    utilityPrice = utilityPriceData.electricity.industrial;
else
    utilityPrice = utilityPriceData.electricity.commercial;
end

monthlyCapPrice = electricityMonthlyMax .* utilityPrice.capacityPrice;
hourlyCapPrice = cell2mat(cellfun(@times, split2monthly(ones(8760,1)), ...
    num2cell(max(0, monthlyCapPrice ./ cellfun(@sum, split2monthly(electricityAssumption)))), 'UniformOutput', false)');
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

%% Natural Gas-Fueled CHP + Absorption Chiller
fuelNGHW = zeros(8760,1);
electricityNGHW = zeros(8760,1);
capacityNGHW = ones(8760,1);
standbyElectricityNGHW = 2.6493;
maintNGHW = 0;
thermalDemandNGHW = ones(8760,1);
if gene(1) > 0
T_CHP = (208-32)/1.8;
copNGHW = (((0.0042.*(T_CHP.*1.8+32))-0.1203+(-0.0012.*((3.672101.*(T_CHP.*1.8+32))-(6.123751.*(T_wet.*1.8+38))-145.142594))+0.8582+(-0.008.*(T_wet.*1.8+38))+1.43+0.76)./4);
capacityNGHW = max(((3.672101.*(T_CHP.*1.8+32))-(6.123751.*(T_wet.*1.8+38))-145.142594)./100, 0.5); % limit cooling capacity to 50% no matter ambient temperature
thermalDemandNGHW = 1./ capacityNGHW./ copNGHW; % kwh of thermal required to produce kwh of cooling 
HWCHPSize(1) = max(thermalDemandNGHW) * gene(1);
fuelNGHW = (0.260107*log(HWCHPSize(1))+0.495783) .* thermalDemandNGHW; % size the CHP based on maximum heating demand m3 of NG used for kwh of CHP heating 
electricityNGHW = - ((1.2327.*thermalDemandNGHW)-357.87 ./ gene(1) ./ capacityNGHW) ... % kwh electricity by-product
            + 0.0025; % kwh of electricity used for kwh of cooling

maintNGHW = min(1e-10*CHPelectric(HWCHPSize(1), "NG")^2-3e-6*CHPelectric(HWCHPSize(1), "NG")+0.0232, 100);
end

%% Hydrogen-Fueled CHP + Absorption Chiller
fuelH2HW = zeros(8760,1);
electricityH2HW = zeros(8760,1);
capacityH2HW = ones(8760,1);
standbyElectricityH2HW = 2.6493;
maintH2HW = 0;
thermalDemandH2HW = ones(8760,1);
if gene(2) > 0
T_CHP = (208-32)/1.8;
copH2HW = (((0.0042.*(T_CHP.*1.8+32))-0.1203+(-0.0012.*((3.672101.*(T_CHP.*1.8+32))-(6.123751.*(T_wet.*1.8+38))-145.142594))+0.8582+(-0.008.*(T_wet.*1.8+38))+1.43+0.76)./4);
capacityH2HW = max(((3.672101.*(T_CHP.*1.8+32))-(6.123751.*(T_wet.*1.8+38))-145.142594)./100, 0.5);
thermalDemandH2HW = 1./ capacityH2HW./ copH2HW; % kwh of thermal required to produce kwh of cooling 
HWCHPSize(2) = max(thermalDemandH2HW) * gene(2);
fuelH2HW = interp1([0,129,183,250,371,687,68700],[0,360.7735,515.54,735.5159,1051.2974,2158.2291,215822.9061], HWCHPSize(2),'makima') ./ HWCHPSize(2) .* thermalDemandH2HW ./ 42.55157; % 42.55157kwh/kg of hydrogen
electricityH2HW = - ((1.2327.*thermalDemandH2HW)-357.87 ./ gene(2) ./ capacityH2HW) ... % kwh electricity by-product
            + 0.0025; % kwh of electricity used for kwh of cooling
        
maintH2HW = min((1e-10*CHPelectric(HWCHPSize(2),"H2")^2-3e-6*CHPelectric(HWCHPSize(2),"H2")+0.0232) .*1.15, 100); % 15% higher than normal CHP as per Doug Edgar
end

%% Biomass-Fueled CHP + Absorption Chiller
fuelBMHW = 0; %zeros(8760,1);
electricityBMHW = zeros(8760,1);
capacityBMHW = ones(8760,1);
standbyElectricityBMHW = 2.6493;
maintBMHW = 0;
thermalDemandBMHW = ones(8760,1);
if gene(3) > 0
T_CHP = (208-32)/1.8;
copNGHW = (((0.0042.*(T_CHP.*1.8+32))-0.1203+(-0.0012.*((3.672101.*(T_CHP.*1.8+32))-(6.123751.*(T_wet.*1.8+38))-145.142594))+0.8582+(-0.008.*(T_wet.*1.8+38))+1.43+0.76)./4);
capacityBMHW = max(((3.672101.*(T_CHP.*1.8+32))-(6.123751.*(T_wet.*1.8+38))-145.142594)./100, 0.5);
thermalDemandBMHW = 1./ capacityBMHW./ copNGHW; % kwh of thermal required to produce kwh of cooling 
HWCHPSize(3) = max(thermalDemandBMHW) * gene(3);
% m3 of Biomass used for kwh of CHP heating 
% PENDING
fuelBMHW = ((2.9114.* HWCHPSize(3) ./ gene(3))-(586.99 ./ gene(3) ./ min(capacityBMHW))) .* 0.003412 .* 28.3168 ./ 1.1; 
electricityBMHW = - ((1.2327.*thermalDemandBMHW)-357.87 ./ gene(3) ./ capacityBMHW) ... % kwh electricity by-product
            + 0.0025; % kwh of electricity used for kwh of cooling
maintBMHW = min(1e-10*CHPelectric(HWCHPSize(3),"BM")^2-3e-6*CHPelectric(HWCHPSize(3),"BM")+0.0232, 100);
end
%% Natural Gas-Fired Absorption Chiller
fuelNG = 1./(((-1.3248.*(T_amb.*1.8+32))+226.78)./100)./1.36.*(((1.5873.*(T_amb.*1.8+32))-52.716)/100);
electricityNG = (0.0315./(((-1.3248.*(T_amb.*1.8+32))+226.78)./100));
standbyFuelNG = 0.2713;
capacityNG = ((-1.3248.*(T_amb.*1.8+32))+226.78)./100;

%% Hydrogen-Fired Absorption Chiller
fuelH2 = 1./ 1.15374 ./ 42.55157; % 42.55157 kwh/kg of hydrogen
electricityH2 = 1 / 100.3571;
capacityH2 = ones(8760,1);

%% Biomass-Fired Absorption Chiller
fuelBM = 1./ 1.15374; % PENDING
electricityBM = 1 / 100.3571;
% standbyFuelBM = 0.2713;
capacityBM = ones(8760,1);

%% Electric Air-Cooled Chiller
electricityEA = 1 ./ (6.610281 - 0.0395723 .* T_amb);
if gene(7) > 0
    capacityEA = 10 .^(1.49625 - 0.751105 .* log10(T_amb .* 1.8 + 32) + 0.991409 .* log10(gene(7)))  ./ gene(7);
else
    electricityEA = ones(totalHours,1) .* 100;
    capacityEA = ones(totalHours,1);
end

%% Electric Water-Cooled Chiller
electricityEW = (((0.154./(((-0.0453.*((((T_wet.*9)./5)+32+6).^2))+(7.2415.*(((T_wet.*9)./5)+32+6))-188.82)./100))).*(((1.636.*(((T_wet.*9)/5)+32+6))-43.741)./100) ...
            + (0.0358./(((-0.0453.*((((T_wet.*9)./5)+32+6).^2))+(7.2415.*(((T_wet.*9)/5)+32+6))-188.82)./100)));
standbyElectricityEW = (21.401.*(((1.636.*(((T_wet.*9)./5)+32+6))-43.741)./100) + 2.8562);
capacityEW = ((-0.0453.*((T_wet.*9./5+32+6).^2))+(7.2415.*(T_wet.*9./5+32+6))-188.82 ) ./100;


%% Natural Gas-Fueled CHP
NGCHPElectricCredit = max(CHPelectric(gene(9), "NG") / gene(9), 0);
fuelNGCHP = max(0.260107*log(gene(9))+0.495783, 1+NGCHPElectricCredit);
maintNGCHP = min(1e-10*CHPelectric(gene(9), "NG")^2-3e-6*CHPelectric(gene(9), "NG")+0.0232, 100);

%% Hydrogen-Fueled CHP
fuelH2CHP = 3.21939 ./ 42.55157; % 42.55157 kwh/kg of hydrogen
H2CHPElectricCredit = max(CHPelectric(gene(10),"H2") / gene(10), 0);
maintH2CHP = min((1e-10*CHPelectric(gene(10),"H2")^2-3e-6*CHPelectric(gene(10),"H2")+0.0232) .*1.15, 100); % 15% higher than normal CHP as per Doug Edgar

%% Biomass-Fueled CHP PENDING
fuelBMCHP = 3.21 ./ 39.44;
BMCHPElectricCredit = max(CHPelectric(gene(11),"BM") / gene(11), 0);
maintBMCHP = min(1e-10*CHPelectric(gene(11),"BM")^2-3e-6*CHPelectric(gene(11),"BM")+0.0232, 100);

%% Natural Gas-Fired Boiler
fuelNGB = 1.15;

%% Hydrogen-Fired Boiler
fuelH2B = 1 / 0.7952 ./ 42.55157; % 79.52% effienency, 42.55157 kwh/kg of hydrogen
electricityH2B = 1 / 82.5;

%% Biomass-Fired Boiler
fuelBMB = 1.15; % PENDING

%% Electric Boiler
electricityEB = 1.1;

%% maintenance cost per kwh for 
%%
unitCost = [fuelNGHW .* naturalGasPrice + electricityNGHW .* (priceGrid) + maintNGHW, ...
    fuelH2HW .* hydrogenPrice + electricityH2HW .* (priceGrid) + maintH2HW, ...
    fuelBMHW .* financialGoals.biomassPrice .* ones(8760,1) + electricityBMHW .* (priceGrid) + maintBMHW, ...
    fuelNG .* naturalGasPrice + electricityNG .* (priceGrid), ...
    fuelH2 .* hydrogenPrice + electricityH2 .* (priceGrid), ...
    fuelBM .* financialGoals.biomassPrice .* ones(8760,1) + electricityBM .* (priceGrid), ...
    [electricityEA, electricityEW] .* (priceGrid), ...
    (fuelNGCHP .* naturalGasPrice + maintNGCHP - NGCHPElectricCredit .* (priceGrid)), ...
    (fuelH2CHP .* hydrogenPrice + maintH2CHP - H2CHPElectricCredit .* (priceGrid)), ...
    (fuelBMCHP .* financialGoals.biomassPrice .* ones(8760,1) + maintBMCHP - BMCHPElectricCredit .* (priceGrid)), ...
    fuelNGB .* naturalGasPrice, fuelH2B .* hydrogenPrice + electricityH2B .* priceGrid, ...
    fuelBMB .* financialGoals.biomassPrice .* ones(8760,1), ...
    electricityEB .* (priceGrid)];
%unitCost(unitCost > 100) = 100;
unitCost(isnan(unitCost)) = 100;


%% greedy algorithm for district cooling
%tic
if financialGoals.systemType == "District Cooling"
capacity = [capacityNGHW, capacityH2HW, capacityBMHW, capacityNG, capacityH2, capacityBM, capacityEA, capacityEW];

for t = 1:computationLength
    unitCostGreedy = unitCost(t,1:8) ./ (gene(1:8) > 0);
    [Sch(t,1:8), tank(t + 1), remainder(t), fminconMaxAttempts]...
        = schedulerDE(gene([1:8,16]) .* [capacity(t,:),1], demand(t),...
        tank(t), tankMin(t), unitCostGreedy, fminconMaxAttempts);
end
%% district heating
else %if financialGoals.systemType == "District Heating"
    tempSch = zeros(totalHours,8);
    unitCostGreedy = unitCost(1,9:15) ./ (gene(9:15) > 0);
    for t = 1:computationLength
        [tempSch(t,:), tank(t + 1), remainder(t), fminconMaxAttempts]...
        = schedulerDE([gene(9:15), 0], demand(t),...
        tank(t), tankMin(t), [unitCostGreedy, inf], fminconMaxAttempts);
    end
    Sch(:,9:15) = tempSch(:,1:7);
end
%% calculate fuel and electricity consumption for each technology

fuelConsumption = [Sch(:, 1:14) .* [fuelNGHW, fuelH2HW, fuelBMHW .* ones(8760,1), fuelNG, ...
    ones(8760,10) .* [fuelH2, fuelBM, 0, 0, fuelNGCHP, fuelH2CHP, fuelBMCHP, fuelNGB, fuelH2B, fuelBMB]], zeros(8760,2)];
fuelConsumption(:,4) = fuelConsumption(:,4) + (Sch(:,4) > 0) .* standbyFuelNG;

electricityConsumption = [Sch(:, 1:15) .* [electricityNGHW, electricityH2HW, electricityBMHW, ...
    electricityNG, ones(8760,2) .* [electricityH2, electricityBM], electricityEA, electricityEW, ...
    ones(8760,3) .* [-NGCHPElectricCredit, -H2CHPElectricCredit, -BMCHPElectricCredit], ...
    zeros(8760,1), ones(8760,1) .* electricityH2B, zeros(8760,1), ones(8760,1) .* electricityEB], zeros(8760,1)];
electricityConsumption(:,1) = electricityConsumption(:,1) + (Sch(:,1) > 0) .* standbyElectricityNGHW;
electricityConsumption(:,3) = electricityConsumption(:,3) + (Sch(:,3) > 0) .* standbyElectricityBMHW;
electricityConsumption(:,8) = electricityConsumption(:,8) + (Sch(:,8) > 0) .* standbyElectricityEW;

Sch(:, 16) = diff(tank);
tank = tank(2:totalHours+1);
%% calculate actual fuel and electricity price
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

%% calculate fuel and electricity cost for each technology
fuelCost = fuelConsumption .* [naturalGasPrice, hydrogenPriceActual, ...
    financialGoals.biomassPrice .* ones(8760,1), naturalGasPrice, ...
    hydrogenPriceActual, financialGoals.biomassPrice .* ones(8760,1), ...
    zeros(8760,2), naturalGasPrice, hydrogenPriceActual, ...
    financialGoals.biomassPrice .* ones(8760,1), naturalGasPrice, ...
    hydrogenPriceActual, financialGoals.biomassPrice .* ones(8760,1), ...
    zeros(8760,2)];

electricityCost = electricityConsumption .* electricityPriceActual;

%% calculate operation cost for each technology
%opCost(1:computationLength, [1,2,3,4,5,6,7]) = fuelCost(1:computationLength,[1 2 3 4 5 6 7]);

%% penalty for infeasible schedule
% airElectricChillerCost(max(remainder) * 2)
% electricityCost(7) = electricityCost(7) + remainder .* electricityEA .* electricityPriceActual;
% electricityBoilerCost(max(remainder) * 2);
% electricityCost(15) = electricityCost(15) + remainder .* electricityEB .* electricityPriceActual;
idx = find(remainder > 0);
%[idx,P(idx),Sch(idx,:),remainder(idx)]
electricityCost(idx, 16) = demand(idx) * financialGoals.electricityPrice * 1000;
%%


%annualOpCost = sum(opCost, 'all');
%techOpCost = sum(opCost);
techMaintCost(1:15) = gene(1:15);
techMaintCost(9:11) = sum(Sch(:, 9:11)) .* [maintNGCHP, maintH2CHP, maintBMCHP] ...
    + sum(Sch(:, 1:3) .* [thermalDemandNGHW, thermalDemandH2HW, thermalDemandBMHW]) .* [maintNGHW, maintH2HW, maintBMHW];
for i = 1:length(lifeCycle)
    lifeCycle(i) = nnz(Sch(:,i));        % Runtime of units 
end

end