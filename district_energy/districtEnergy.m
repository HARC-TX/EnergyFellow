function [sitting_result, siz_sch_result,uniqueGene] = ...
    districtEnergy(nbus,dist,thermal_load, cooling_load,weather,pipeData,newTechs,data_genetic, financialGoals)

if financialGoals.systemType == "District Cooling"
    load = cooling_load;
else %if financialGoals.systemType == "District Heating"
    load = thermal_load;
end

%%   Set lower and upper bounds
total_load = sum(load,2);
[minBound, maxBound] = findBoundsDE(financialGoals, total_load, newTechs(1, :));

%% Call GA
[resultDE, cgcurve, uniqueGene] = gaDistrictCooling(data_genetic(1,3), data_genetic(2,3), ...
        data_genetic(3,3), data_genetic(4,3), data_genetic(5,3),minBound, maxBound, ...
        nbus,dist,load,weather,pipeData, financialGoals,newTechs(1, :));
%% Eveluate customized solution
if sum(dist(:,4)) > 0 && sum(newTechs(2,:)) > 0
    temp.Gene = [newTechs(2,:), (dist(:,4)' > 0) .* find(strcmp(pipeData.Properties.RowNames, string(mean(nonzeros(dist(:,4)')))))];
    
    [temp.npv, temp.schedule, temp.powerCost, ...
        temp.sittingCashFlow, temp.sizingCashFlow, temp.techData]...
        = fitnessDE(temp.Gene, load, nbus,dist,pipeData, weather, financialGoals);
    resultDE = [resultDE, temp];
end
%% split result
for i = 1:length(resultDE)
    sittingTemp = resultDE(i).sittingCashFlow;
    sittingTemp.topology = (resultDE(i).Gene(17:end) > 0) .* str2num(pipeData(mean(nonzeros(resultDE(i).Gene(17:end))),:).Properties.RowNames{:});
    sittingTemp.npv_val = pvvar(resultDE(i).sittingCashFlow.cash_flow, financialGoals.interestRate);
    sittingTemp.power_loss_cost = zeros(1, financialGoals.lifespan + 1);
    sitting_result(i) = sittingTemp;
    
    sizingTemp = resultDE(i).sizingCashFlow;
    sizingTemp.state_vector = (resultDE(i).Gene(1:16) > 0);
    sizingTemp.optimal_size = resultDE(i).Gene(1:16);
    sizingTemp.npv = pvvar(resultDE(i).sizingCashFlow.cash_flow, financialGoals.interestRate);
    sizingTemp.power_generated = resultDE(i).schedule;
    sizingTemp.power_cost = resultDE(i).powerCost;
    
    selectBuilding = getBuilding(resultDE(i).Gene(17:end), nbus);
    sizingTemp.power_load = [];
    sizingTemp.thermal_load = sum(load(:, (selectBuilding-1)),2);
    sizingTemp.techData = resultDE(i).techData;
    siz_sch_result(i) = sizingTemp;
end

