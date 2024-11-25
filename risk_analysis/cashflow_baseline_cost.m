function [cashflow_baseline, baselineCashflowMC] = cashflow_baseline_cost(sitting_results, financialGoals, fuel_table)

if financialGoals.systemType == "Micro Grid"
    
    baselineCashflowMC = repmat([zeros(size(fuel_table.electricity,1),1), ...
        -financialGoals.electricityBaselineCost .* fuel_table.electricity], [1 1 6]);
    
    cashflow_baseline = repmat([0, -financialGoals.electricityBaselineCost .*...
        sum(fuel_table.electricity, 1) / size(fuel_table.electricity,1)], [6 1]);
    % NPV_baseline = pvvar(cashflow_baseline', financialGoals.interestRate);
    
else
    if financialGoals.systemType == "District Cooling"
        for i = 1:size(sitting_results,2)
            selectBuilding = getBuilding(sitting_results(i).topology, 0);
            baselineCashflowMC(:,:,i) = [zeros(size(fuel_table.electricity,1),1), ...
                -sum(financialGoals.coolingBaselineCost(selectBuilding-1)) .* fuel_table.electricity];
            cashflow_baseline(i,:) = [0, -sum(financialGoals.coolingBaselineCost(selectBuilding-1)) .*...
                sum(fuel_table.electricity, 1) / size(fuel_table.electricity,1)];
        end
    else %if financialGoals.systemType == "District Heating"
        for i = 1:size(sitting_results,2)
            selectBuilding = getBuilding(sitting_results(i).topology, 0);
            baselineCashflowMC(:,:,i) = [zeros(size(fuel_table.electricity,1),1), ...
                -sum(financialGoals.naturalGasBaselineCost(selectBuilding-1)) .* fuel_table.naturalGas];
            cashflow_baseline(i,:) = [0, -sum(financialGoals.naturalGasBaselineCost(selectBuilding-1)) .*...
                sum(fuel_table.electricity, 1) / size(fuel_table.naturalGas,1)];
        end
    end
end
end
