function[siz_sch_result, uniqueGene]= sizing_scheduling(financialGoals,power_load,...
    thermal_load,weather_data,tech_data,data_genetic, state_tech,SolarMatrix,solarProdMatrix)%%  Reading of data

tot_power_load=sum(power_load,2);
[~, maxThermalBuilding] = max(sum(thermal_load));

%%  Test Inputs
[solar_irad, T_amb, T_cell, Hours, hours]  = readWeather(weather_data);
PV_rated = 1000; %tech_data.PV_rated;
%PV_rated=PV_rated(1);
Temp_coeff=tech_data.Temp_coeff;
Temp_coeff=Temp_coeff(1);
eff_pv=tech_data.eff_pv;
eff_pv=eff_pv(1);
% PV output in kW
for i = 1:length(solar_irad)
    PV(i) = funcPV(solar_irad(i), T_amb(i), T_cell(i), PV_rated,Temp_coeff,eff_pv);
end

%%   Set lower and upper bounds
[minBound, maxBound] = findBounds(tech_data, financialGoals, tot_power_load,...
    thermal_load(:, maxThermalBuilding),state_tech(1, :),SolarMatrix,solarProdMatrix);

%% Genetic Algorithm parameters and function call
Problem.obj = @fitnessFunction;
Problem.nVar = length(maxBound);
Problem.lb = ones(1, Problem.nVar).* minBound;
Problem.ub = ones(1, Problem.nVar).* maxBound;
if data_genetic(2,2) > 0 && data_genetic(1,2) > 4 %&& sum(state_tech(2, :)) <= 0
    [siz_sch_result, cgcurve, uniqueGene] = ga_Sizing(Problem, data_genetic(1,2), data_genetic(2,2), ...
        data_genetic(3,2), data_genetic(4,2), data_genetic(5,2), PV, tot_power_load,...
        thermal_load, T_amb, financialGoals,tech_data,state_tech(1, :));
elseif (data_genetic(2,2) <= 0 || data_genetic(1,2) <= 4) && sum(state_tech(2, :)) <= 0
    data_genetic(1:2,2) = [20;2];
    [siz_sch_result, cgcurve, uniqueGene] = ga_Sizing(Problem, data_genetic(1,2), data_genetic(2,2), ...
        data_genetic(3,2), data_genetic(4,2), data_genetic(5,2), PV, tot_power_load,...
        thermal_load, T_amb, financialGoals,tech_data,state_tech(1, :));
end
%% Eveluate customized solution
if sum(state_tech(2, :)) > 0
    [fitness, schedule, powerCost, annualFuel, cashFlows]...
        = fitnessFunction(state_tech(2, :), PV, tot_power_load, thermal_load,...
        T_amb, financialGoals, tech_data, state_tech(1, :));
    if exist('siz_sch_result', 'var')
        siz_sch_result(end+1).state_vector = (state_tech(2, :) > 0);
    else
        siz_sch_result(1).state_vector = (state_tech(2, :) > 0);
        uniqueGene = 1;
    end
    siz_sch_result(end).optimal_size = state_tech(2, :);
    siz_sch_result(end).npv = fitness;
    siz_sch_result(end).power_generated = schedule;
    siz_sch_result(end).power_cost = powerCost;
    siz_sch_result(end).annualFuel = annualFuel;

    siz_sch_result(end).power_load = tot_power_load;
    siz_sch_result(end).thermal_load = thermal_load;
    
    siz_sch_result(end).cash_flow = cashFlows.cashFlow;
    
    
    siz_sch_result(end).capital_cost =  cashFlows.fixedCost;
    siz_sch_result(end).operation_cost = cashFlows.operationCost;
    siz_sch_result(end).maintenance_cost = cashFlows.maintenanceCost;
    siz_sch_result(end).salvage_cost = cashFlows.salvageCost;
    siz_sch_result(end).replacement_cost = cashFlows.replacementCost;
    siz_sch_result(end).detailCost = cashFlows.detailCost;
end
end
