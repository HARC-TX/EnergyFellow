function [data] = gen_output(output_results, financialGoals, newTechs,techNames)

%% Key Financial Indicators
data.keyFinancialIndicators(1).optimization = output_results.FinancialIndicators.initial_investment;
data.keyFinancialIndicators(1).investorGoals = financialGoals.maximumDownPayment;

data.keyFinancialIndicators(2).optimization = output_results.FinancialIndicators.loan;
data.keyFinancialIndicators(2).investorGoals = 0.00;

data.keyFinancialIndicators(3).optimization = output_results.FinancialIndicators.annual_savings;
data.keyFinancialIndicators(3).investorGoals = 0.00;

data.keyFinancialIndicators(4).optimization = output_results.FinancialIndicators.NPV;
data.keyFinancialIndicators(4).investorGoals = 0.00;

data.keyFinancialIndicators(5).optimization = output_results.FinancialIndicators.IRR;
data.keyFinancialIndicators(5).investorGoals = financialGoals.irr_goal * 100;

data.keyFinancialIndicators(6).optimization = output_results.FinancialIndicators.DPP;
data.keyFinancialIndicators(6).investorGoals = financialGoals.paybackGoal;

data.keyFinancialIndicators(7).optimization = output_results.FinancialIndicators.equivalent_annuity;
data.keyFinancialIndicators(7).investorGoals = 0.00;

%% analyzed solution
data.analyzedSolution = sum(output_results.analyzedSolution);

%% projectCostsBreakdown
data.projectCostsBreakdown = output_results.ProjectCosts;

%% riskAnalysisResults
data.riskAnalysisResults = rmfield(output_results.RiskAnalysisResults, {'NPV', 'irr', 'dpp'});

%% incentivesRequired
data.incentivesRequiredByProfitabilityGoals(1).optimization = output_results.IncentivesForProfit.IRRGoal *100;
data.incentivesRequiredByProfitabilityGoals(1).sensitivity1 = output_results.sensitivity1_for_profit.IRRGoal *100;
data.incentivesRequiredByProfitabilityGoals(1).sensitivity2 = output_results.sensitivity2_for_profit.IRRGoal *100;

data.incentivesRequiredByProfitabilityGoals(2).optimization = output_results.IncentivesForProfit.incentive_for_irr;
data.incentivesRequiredByProfitabilityGoals(2).sensitivity1 = output_results.sensitivity1_for_profit.incentive_for_irr;
data.incentivesRequiredByProfitabilityGoals(2).sensitivity2 = output_results.sensitivity2_for_profit.incentive_for_irr;

data.incentivesRequiredByProfitabilityGoals(3).optimization = output_results.IncentivesForProfit.additional_annual_savings_irr;
data.incentivesRequiredByProfitabilityGoals(3).sensitivity1 = output_results.sensitivity1_for_profit.additional_annual_savings_irr;
data.incentivesRequiredByProfitabilityGoals(3).sensitivity2 = output_results.sensitivity2_for_profit.additional_annual_savings_irr;

data.incentivesRequiredByProfitabilityGoals(4).optimization = output_results.IncentivesForProfit.DPPGoal;
data.incentivesRequiredByProfitabilityGoals(4).sensitivity1 = output_results.sensitivity1_for_profit.DPPGoal;
data.incentivesRequiredByProfitabilityGoals(4).sensitivity2 = output_results.sensitivity2_for_profit.DPPGoal;

data.incentivesRequiredByProfitabilityGoals(5).optimization = output_results.IncentivesForProfit.incentive_for_dpp;
data.incentivesRequiredByProfitabilityGoals(5).sensitivity1 = output_results.sensitivity1_for_profit.incentive_for_dpp;
data.incentivesRequiredByProfitabilityGoals(5).sensitivity2 = output_results.sensitivity2_for_profit.incentive_for_dpp;

data.incentivesRequiredByProfitabilityGoals(6).optimization = output_results.IncentivesForProfit.additional_annual_savings_dpp;
data.incentivesRequiredByProfitabilityGoals(6).sensitivity1 = output_results.sensitivity1_for_profit.additional_annual_savings_dpp;
data.incentivesRequiredByProfitabilityGoals(6).sensitivity2 = output_results.sensitivity2_for_profit.additional_annual_savings_dpp;



%% keyTechIndicators
data.keyTechnicalIndicators = output_results.KeyTechnicalIndicators;

%% powerGeneratorPerformance
j = 0;
for i=1:length(newTechs)
    if(newTechs(1, i) == 1)
        j = j+1;
        data.powerGeneratorsPerformance(j).type = output_results.PowerGeneratorPerformance.techNames(i);
        data.powerGeneratorsPerformance(j).rcCapkW = output_results.PowerGeneratorPerformance.RatedCapacity(i);
        data.powerGeneratorsPerformance(j).maxCapkW = output_results.PowerGeneratorPerformance.MaxCapacity(i);
        data.powerGeneratorsPerformance(j).avgCapkW = output_results.PowerGeneratorPerformance.AverageCapacity(i);
        data.powerGeneratorsPerformance(j).aoh = output_results.PowerGeneratorPerformance.OperatingHours(i);
        data.powerGeneratorsPerformance(j).lifespan = output_results.PowerGeneratorPerformance.Lifespan(i);
        data.powerGeneratorsPerformance(j).starts = output_results.PowerGeneratorPerformance.Starts(i);
        data.powerGeneratorsPerformance(j).aegkWh = output_results.PowerGeneratorPerformance.EnergyGenerated(i);
        data.powerGeneratorsPerformance(j).atokWh = output_results.PowerGeneratorPerformance.ThermalOutput(i);
        data.powerGeneratorsPerformance(j).aekWh = output_results.PowerGeneratorPerformance.ElectricityConsumption(i);
        data.powerGeneratorsPerformance(j).afkWh = output_results.PowerGeneratorPerformance.FuelCapacity(i);
        data.powerGeneratorsPerformance(j).efficiency = output_results.PowerGeneratorPerformance.Efficiency(i);
        data.powerGeneratorsPerformance(j).aeekg = output_results.PowerGeneratorPerformance.EnvEmissions(i);
    end

end
data.pathConnections = output_results.pathConnections;
%% curves
data.loadDurationCurve = output_results.LoadDurationCurve(:, 2);
data.energyExchangedTank = [];
data.waterTempTank = [];
data.energyExchangedBattery = [];
data.stateOfCharge = [];

if financialGoals.systemType == "Micro Grid"
    tankRateCapacity = output_results.PowerGeneratorPerformance.RatedCapacity(11);
else
    tankRateCapacity = output_results.PowerGeneratorPerformance.RatedCapacity(16);
end
        
if tankRateCapacity > 0 && any(output_results.energyExchangedTank)
data.energyExchangedTank = output_results.energyExchangedTank;
cumEnergyExchangedTank = cumsum(output_results.energyExchangedTank, 'omitnan');
data.waterTempTank = (tankRateCapacity...
    - max(cumEnergyExchangedTank) + cumEnergyExchangedTank)...
    / tankRateCapacity * (financialGoals.tankFullTemp - financialGoals.tankEmptyTemp) + financialGoals.tankEmptyTemp;
end

if financialGoals.systemType == "Micro Grid" ...
        && output_results.PowerGeneratorPerformance.RatedCapacity(10) > 0 ...
        && any(output_results.energyExchangedBattery)
data.energyExchangedBattery = output_results.energyExchangedBattery;
cumEnergyExchangedBattery = cumsum(output_results.energyExchangedBattery, 'omitnan');
data.stateOfCharge = (output_results.PowerGeneratorPerformance.RatedCapacity(10)...
    - max(cumEnergyExchangedBattery) + cumEnergyExchangedBattery)...
    / output_results.PowerGeneratorPerformance.RatedCapacity(10);
end

%% data trimming
data = round_struct(data, 2);
if length(data.powerGeneratorsPerformance) == 1
    data.powerGeneratorsPerformance = {data.powerGeneratorsPerformance};
end
if length(data.pathConnections) == 1
    data.pathConnections = {data.pathConnections};
end

data.detailCashFlow = output_results.detailCashFlow;

end
