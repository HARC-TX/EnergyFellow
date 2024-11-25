function [nbus,dist,power_load,thermal_load,cooling_load,lines_data,...
        tech_data,weather_data,data_genetic,pipeData,newTechs,techNames, financialGoals,...
        SolarMatrix, solarProdMatrix] = read_json(inputJSON)

global web_host

nbus = length(inputJSON.buildings);
if inputJSON.interestRate < 0.1
    inputJSON.interestRate = 100 * inputJSON.interestRate;
    log_function(sprintf("interestRate %f is less than 0.1% and has been corrected",...
        inputJSON.interestRate / 100), 'error');
end
if inputJSON.interestRateLoan < 0.1
    inputJSON.interestRateLoan = 100 * inputJSON.interestRateLoan;
    log_function(sprintf("interestRateLoan %f is less than 0.1% and has been corrected",...
        inputJSON.interestRate / 100), 'error');
end

%% Technologies %%%%%%%%%
techMap = containers.Map('KeyType','char','ValueType','double');
financialGoals.systemType = inputJSON.systemType;
techNames = ["Natural Gas-Fueled CHP + Absorption Chiller" ... % cooling
    "Hydrogen-Fueled CHP + Absorption Chiller" ...
    "Biomass-Fueled CHP + Absorption Chiller" ...
    "Natural Gas-Fired Absorption Chiller" ...
    "Hydrogen-Fired Absorption Chiller" ...
    "Biomass-Fired Absorption Chiller" ...
    "Electric Air-Cooled Chiller" ...
    "Electric Water-Cooled Chiller" ...
    "Natural Gas-Fueled CHP" ... % heating
    "Hydrogen-Fueled CHP" ...
    "Biomass-Fueled CHP" ...
    "Natural Gas-Fired Boiler" ...
    "Hydrogen-Fired Boiler" ...
    "Biomass-Fired Boiler" ...
    "Electric Boiler" ...
    "Thermal Energy Storage"];
connectionType = "pipeSize";
financialGoals.tankEmptyTemp = 50;
financialGoals.tankFullTemp = 100;
switch financialGoals.systemType
    case "Micro Grid"
        techNames = ["Ground-Based Solar" ...
            "Rooftop Solar" ...
            "Natural Gas-Fueled CHP" ...
            "Hydrogen-Fueled CHP" ...
            "Biomass-Fueled CHP" ...
            "Natural Gas-Fueled Generator" ...
            "Diesel-Fueled Generator" ...
            "Hydrogen-Fueled Generator" ...
            "Biomass-Fueled Generator" ...
            "Battery Storage" ...
            "Thermal Storage for CHP" ...
            "Power Grid"];
        connectionType = "cableType";
    case "District Cooling"
        financialGoals.supplyTemperature = 6.67;
        financialGoals.returnTemperature = 12.8;
        financialGoals.tankEmptyTemp = 12.778;
        financialGoals.tankFullTemp = 6.667;
    case "District Heating"
        financialGoals.supplyTemperature = 80;
        financialGoals.returnTemperature = 60;
        financialGoals.tankEmptyTemp = 60;
        financialGoals.tankFullTemp = 80;
    otherwise
        log_function("Unknown system type", 'error');
        quit(249);
end
for i = 1:size(techNames, 2)
    techMap(techNames(i)) = i;
end
userTechs = inputJSON.selectedTechnologies;

newTechs = zeros(2, size(techNames, 2));
for i = 1:length(userTechs)
    newTechs(1,techMap(string(userTechs(i)))) = 1;
end

%% Sized Selected Technologies %%%%%%%%%
if isfield(inputJSON, "selectedTechnologySizes")
    for i = 1:length(inputJSON.selectedTechnologySizes)
        newTechs(2,techMap((inputJSON.selectedTechnologySizes(i).technologyName))) ...
            = inputJSON.selectedTechnologySizes(i).selectedSize;
    end
end

%% building id Mapping
nlines = length(inputJSON.pathConnections);
M = containers.Map('KeyType', 'char', 'ValueType', 'double');

for i = 1:nbus
    M(inputJSON.buildings(i).id) = i + 1;
end  

%% add Substation to map
for i = 1:length(inputJSON.components)
    if(any(inputJSON.components(i).systemType == ["Substation", "Central Plant"]))
        M(inputJSON.components(i).id) = 1;
        break;
    end
end

%% add SolarProductdionArea to map
solarProdMatrix = zeros(length(inputJSON.solarProductionAreas), 3);
for i = 1:length(inputJSON.solarProductionAreas)
    M(inputJSON.solarProductionAreas(i).id) = (-1)*i;
    solarProdMatrix(i, 1) = (-1)*i;
    solarProdMatrix(i, 2) = inputJSON.solarProductionAreas(i).area;
    solarProdMatrix(i, 3) = inputJSON.solarProductionAreas(i).capacity;
end

%% add connections to table
dist = table('Size', [0 5], 'VariableTypes', ["double" "double" "double" "double" "string"], ...
    'VariableNames', ["buildingIdxA", "buildingIdxB", "distance", connectionType, "connectionId"]);
for i = 1:nlines
    A = inputJSON.pathConnections(i).building1_id;
    B = inputJSON.pathConnections(i).building2_id;
    C = inputJSON.pathConnections(i).distanceInMeters;
    try
        if inputJSON.pathConnections(i).selected
            D = inputJSON.pathConnections(i).(connectionType); % cableType
        else
            D = 0;
        end
    catch
        D = 0;
    end
    try
        if M(B) <= abs(M(A))
            dist(end +1, :) = table(M(B), M(A), C, D, string(inputJSON.pathConnections(i).id));
        else
            dist(end +1, :) = table(M(A), M(B), C, D, string(inputJSON.pathConnections(i).id));
        end
    catch
        log_function(sprintf("Unrecognized pathConnections(%i)", i), 'error');
    end
end
if size(dist, 1) < nbus*(nbus+1)/2 + length(inputJSON.solarProductionAreas)
    log_function(sprintf("NO enough pathConnections, only phrased %i connections)", size(dist, 1)), 'error');
    quit(249)
end
dist = sortrows(dist);


%% Electricity Price %%%%%%%
if inputJSON.electricityPrice > 0
    electricityPrice = inputJSON.electricityPrice;
    electricityPriceInput = "true";
else
    electricityPrice = 0.1;
    electricityPriceInput = "false";
    log_function("ZERO electricityPrice, set to 0.1", 'error');
end
if inputJSON.naturalGasPrice > 0
    naturalGasPrice = inputJSON.naturalGasPrice / 293.07107; % $/mmbtu to $/kwh
    naturalGasPriceInput = "true";
else
    naturalGasPrice = 0.0214931;
    naturalGasPriceInput = "false";
    % log_function("ZERO naturalGasPrice, set to $0.2306/m3($6.53/thousand cubic ft)(2020)", 'error');
    log_function("ZERO naturalGasPrice, set to $0.0214931/kwh(%6.299/mmbtu,$0.2306/m3,$6.53/thousand cubic ft)(2020)", 'error');
end

%% Technical Data
load RefBldg;

power_load = nan(8760, nbus);
thermal_load = nan(8760, nbus);
cooling_load = nan(8760, nbus);

fuelRatio = nan(8760, nbus);
%% Power Load & Baseline Cost
electricityBaselineCost = sum([inputJSON.buildings.electricityCost]);
naturalGasBaselineCost = [inputJSON.buildings.fuelCost];
coolingBaselineCost = zeros(nbus,1);
for i = 1: nbus
    sqFt_building = inputJSON.buildings(i).area;
    building_type = strrep(lower(inputJSON.buildings(i).buildingType),' ','');
    %% Electricity
    powerLoadTmp = inputJSON.buildings(i).userSuppliedPowerDemandData;
    powerRatio = [];
    if length(powerLoadTmp) == 35040
        power_load(:, i) = sum(reshape(powerLoadTmp, [4 8760]), 1)';
        powerRatio = ones(8760, 1) .* (sum(powerLoadTmp) / sum(RefBldg.(building_type).TotalKW));
    elseif length(powerLoadTmp) == 8760
        power_load(:, i) = reshape(powerLoadTmp, [8760 1]);
        powerRatio = power_load(:, i) ./ RefBldg.(building_type).TotalKW;
    else
        if isempty(powerLoadTmp)
            power_load(:, i) = RefBldg.(building_type).TotalKW * (sqFt_building / RefBldg.refbldgfloorarea{building_type,"FLOORAREAFT2"});
            powerRatio = ones(8760, 1) .* (sqFt_building / RefBldg.refbldgfloorarea{building_type,"FLOORAREAFT2"});
        else
            power_load(:, i) = RefBldg.(building_type).TotalKW * (sum(powerLoadTmp) / sum(RefBldg.(lower(building_type)).TotalKW));
            powerRatio = ones(8760, 1) .* (sum(powerLoadTmp) / sum(RefBldg.(lower(building_type)).TotalKW));
        end
    end
    if inputJSON.buildings(i).electricityCost == 0
        electricityBaselineCost = electricityBaselineCost + sum(power_load(:,i)) * electricityPrice;
    end
    %% Thermal
    fuelDemandTmp = inputJSON.buildings(i).userSuppliedFuelDemandData .* 293.07107; % convert mmbtu to kwh
    boilerEfficiency(i) = inputJSON.buildings(i).userSuppliedBoilerEfficiency;
    if boilerEfficiency(i) == 0
        boilerEfficiency(i) = inputJSON.buildings(i).boilerEfficiency;
    end
    if boilerEfficiency(i) > 1
        boilerEfficiency(i) = 0.01 * boilerEfficiency(i);
        log_function(sprintf("biulding %i has an boilerEfficiency %.2f over 100%% and been corrected",...
            i, boilerEfficiency(i) * 1e4), 'error');
    end
    if length(fuelDemandTmp) == 35040
        fuelRatio(:, i) = sum(reshape(fuelDemandTmp, [4 8760]), 1)' ./ RefBldg.(building_type).TotalNG;
    elseif length(fuelDemandTmp) == 8760
        fuelRatio(:, i) = reshape(fuelDemandTmp, [8760 1]) ./ RefBldg.(building_type).TotalNG;
    elseif ~isempty(fuelDemandTmp)
        fuelRatio(:, i) = ones(8760,1) .* (sum(fuelDemandTmp) / sum(RefBldg.(building_type).TotalNG));
    else
        fuelRatio(:, i) = ones(8760,1) .* (sqFt_building / RefBldg.refbldgfloorarea{building_type,"FLOORAREAFT2"});
    end
    thermal_load(:,i) = (RefBldg.(building_type).FuelhRefbuilding .* fuelRatio(:,i) + RefBldg.(building_type).KWForHeating .* powerRatio) .* boilerEfficiency(i);
    
    if naturalGasBaselineCost(i) == 0
        naturalGasBaselineCost(i) = sum(thermal_load(:,i))...
            / boilerEfficiency(i) * naturalGasPrice; % kwh of natural gas
    end
    
    %% Cooling
    chillerEfficiency(i) = inputJSON.buildings(i).userSuppliedChillerEfficiency;
    if chillerEfficiency(i) == 0
        chillerEfficiency(i) = inputJSON.buildings(i).chillerEfficiency;
    end
    cooling_load(:, i) = RefBldg.(building_type).PWhCoolingRefBuilding .* powerRatio * chillerEfficiency(i);
    coolingBaselineCost(i) = sum(cooling_load(:,i)) ./ chillerEfficiency(i) * electricityPrice;
end
%disp(power_load);
if financialGoals.systemType == "Micro Grid" && max(sum(power_load, 2)) < 2
    log_function(sprintf("peak hourly power demand less than 2kwh"), 'error');
    quit(249)
end
if financialGoals.systemType == "District Heating" && max(sum(thermal_load, 2)) < 2
    log_function(sprintf("peak hourly thermal demand less than 2kwh"), 'error');
    quit(249)
end
if financialGoals.systemType == "District Cooling" && max(sum(cooling_load, 2)) < 2
    log_function(sprintf("peak hourly cooling demand less than 2kwh"), 'error');
    quit(249)
end
%% include SolarMatrix
for i=1:nbus
    includeSolar(i, 1) = (M(inputJSON.buildings(i).id));
    if(inputJSON.buildings(i).includeSolar == false)
       SolarMatrix(i).includeSolar = 0;
    else
       SolarMatrix(i).includeSolar = 1;
    end
       SolarMatrix(i).usableSolar= inputJSON.buildings(i).usableSolar;
       SolarMatrix(i).esitmatedFloorCount = inputJSON.buildings(i).estimatedFloorCount;
       SolarMatrix(i).footprintArea = inputJSON.buildings(i).footprintArea;
       SolarMatrix(i).electricityProduction= inputJSON.buildings(i).electricityProduction;
       SolarMatrix(i).yearBuilt = inputJSON.buildings(i).yearBuilt;
       SolarMatrix(i).capacity = inputJSON.buildings(i).electricityProduction / 1.42248;
end
% disp(includeSolar);

%% Include substation to number of buses %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nbus = nbus + 1;

load technical_data


%%%%
financialGoals.lifespan = inputJSON.lifespan;
financialGoals.paybackGoal = inputJSON.paybackGoal;
financialGoals.irr_goal = inputJSON.iir_goal * (1e-2);
financialGoals.maximumDownPayment = inputJSON.maximumDownPayment;
financialGoals.interestRate = inputJSON.interestRate*(1e-2);
financialGoals.interestRateLoan = inputJSON.interestRateLoan*(1e-2);
financialGoals.environmentalGoal = inputJSON.environmentalGoal;
financialGoals.carbonGoal = inputJSON.carbonGoal;
financialGoals.resilienceGoalTime = ceil(inputJSON.resilienceGoalTime);
financialGoals.resilienceGoalLoad = inputJSON.resilienceGoalLoad;
financialGoals.naturalGasPrice = naturalGasPrice;
financialGoals.naturalGasPriceInput = naturalGasPriceInput;
financialGoals.naturalGasPriceEscalation = inputJSON.naturalGasPriceEscalation;
financialGoals.naturalGasDeterminationMethod = inputJSON.naturalGasDeterminationMethod;

financialGoals.electricityPrice= electricityPrice;
financialGoals.electricityPriceInput = electricityPriceInput;
financialGoals.electricityPriceEscalation = inputJSON.electricityPriceEscalation;
financialGoals.electricityDeterminationMethod = inputJSON.electricityDeterminationMethod;

financialGoals.electricityBuybackRate = electricityPrice;

if inputJSON.dieselPrice ~= 0
    financialGoals.dieselPrice = inputJSON.dieselPrice/3.7854;
    financialGoals.dieselPriceInput = "true";
else
    financialGoals.dieselPrice = 3.04/3.7854;
    financialGoals.dieselPriceInput = "false";
    log_function("ZERO dieselPrice, set to $0.803/L($3.04/gallon)", 'error');
end
financialGoals.dieselPriceEscalation = inputJSON.dieselPriceEscalation;
financialGoals.dieselDeterminationMethod = inputJSON.dieselDeterminationMethod;

if isfield(inputJSON, "hydrogenPrice") && inputJSON.hydrogenPrice > 0
    financialGoals.hydrogenPrice = inputJSON.hydrogenPrice;
    financialGoals.hydrogenPriceInput = "true";
else
    financialGoals.hydrogenPrice = 1.9; % $1.9/kg flat green hydrogen price
    financialGoals.hydrogenPriceInput = "false";
    log_function("ZERO hydrogenPrice, set to $1.9/kg", 'error');
end
financialGoals.hydrogenPriceEscalation = 0.5;
financialGoals.hydrogenDeterminationMethod = 'Natural';

if isfield(inputJSON, "biomassPrice") && inputJSON.biomassPrice > 0
    financialGoals.biomassPrice = inputJSON.biomassPrice;
    financialGoals.biomassPriceInput = "true";
else
    financialGoals.biomassPrice = 3.04/3.7854; % PENDING
    financialGoals.biomassPriceInput = "false";
    log_function("ZERO biomassPrice, set to $0.803/L($3.04/gallon)", 'error');
end
financialGoals.biomassPriceEscalation = 0.5;
financialGoals.biomassDeterminationMethod = 'Natural';

financialGoals.installationCostEscalation = inputJSON.installationCostEscalation;
financialGoals.installationCostDeterminationMethod = inputJSON.installationCostDeterminationMethod;
financialGoals.omPriceEscalation = inputJSON.omPriceEscalation;
financialGoals.omDeterminationMethod = inputJSON.omDeterminationMethod;
financialGoals.salvageEscalation = inputJSON.salvageEscalation;
financialGoals.salvageDeterminationMethod = inputJSON.salvageDeterminationMethod;
financialGoals.electricityBaselineCost = electricityBaselineCost; 
financialGoals.naturalGasBaselineCost = naturalGasBaselineCost; 
financialGoals.coolingBaselineCost = coolingBaselineCost; 

financialGoals.boilerEfficiency = boilerEfficiency;
financialGoals.chillerEfficiency = chillerEfficiency;


end
