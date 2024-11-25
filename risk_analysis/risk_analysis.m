function[final_results]=risk_analysis(sitting_results,sizing_results,...
    dist, lines_data, tech_data, techNames, financialGoals, sitingUniqueGene, sizingUniqueGene)
caseCount = 1000;
[prob_table]=calcul_prob(tech_data);
fuel_table = calcul_fuel(financialGoals, caseCount);
%% Baseline cashflow and PV calculation
[cashflow_baseline, baselineCashflowMC] = cashflow_baseline_cost(sitting_results, financialGoals, fuel_table);
%% Risk Analysis on Siting Results

siting_risk_results = siting_risk_analysis(sitting_results, prob_table, fuel_table);

%% Risk Analysis on Sizing Results

sizing_risk_results = sizing_risk_analysis(sizing_results, prob_table, fuel_table,financialGoals);

%% Total Cash Flow
mean_cf = zeros(max(size(sitting_results,2), size(sizing_results,2)), ...
    size(siting_risk_results.average_cf(1).mean_cash_flow,2));

for i = 1 : size(mean_cf,1)
mean_cf(i,:) = siting_risk_results.average_cf(mod(i-1, size(siting_risk_results.average_cf,2))+1).mean_cash_flow ...
    + sizing_risk_results.average_cf(mod(i-1, size(sizing_risk_results.average_cf,2))+1).mean_cash_flow;
end


%% Key Indicators

% Key Financial Indicators
key_financial_indicator = key_financial_indicators(mean_cf, financialGoals, cashflow_baseline);

% Project Cost Breakdown
project_costs = project_cost_breakdown(siting_risk_results, sizing_risk_results);

% Key Technical Indicators

key_technical_indicator = key_technical_indicators(sizing_results, sizing_risk_results, financialGoals, tech_data);

% Load Duration curve
load_duration_data = load_duration(sizing_results);

% Risk Analysis Results
npv_at_risk = npv_risk(financialGoals, siting_risk_results, sizing_risk_results, baselineCashflowMC);

% Power Generators Performance
power_generator_performance = power_generators_performance(sizing_results, techNames, tech_data, financialGoals);

% Incentives for profitability goals
incentives_for_profit = incentives_for_profitability(mean_cf, financialGoals,cashflow_baseline);

%% Sensitivity analisis of profitability goals
Sens1FinancialGoals=financialGoals;
Sens1FinancialGoals.irr_goal=financialGoals.irr_goal*0.8;
sensitivity1_for_profit = incentives_for_profitability(mean_cf, Sens1FinancialGoals,cashflow_baseline);
Sens2FinancialGoals=financialGoals;
Sens2FinancialGoals.paybackGoal=ceil(financialGoals.paybackGoal*1.2);
sensitivity2_for_profit = incentives_for_profitability(mean_cf, Sens2FinancialGoals,cashflow_baseline);
Sens3FinancialGoals=financialGoals;
Sens3FinancialGoals.irr_goal=financialGoals.irr_goal*0.6;
Sens3FinancialGoals.paybackGoal=ceil(financialGoals.paybackGoal*1.4);
sensitivity3_for_profit = incentives_for_profitability(mean_cf, Sens3FinancialGoals,cashflow_baseline);

%% Processing of Results
for i = 1:max(size(sitting_results,2), size(sizing_results,2))
    sizingIdx = mod(i - 1, size(sizing_results,2)) + 1;
    sittingIdx = mod(i - 1, size(sitting_results,2)) + 1;
% Key Financial Indicators
final_results(i).FinancialIndicators = key_financial_indicator(i);

% Key Technical Indicators
final_results(i).KeyTechnicalIndicators = key_technical_indicator(sizingIdx);

% analyzed solution
final_results(i).analyzedSolution = [sitingUniqueGene, sizingUniqueGene];

% Project Related Costs
final_results(i).ProjectCosts = project_costs(i);

% Load duration curve
final_results(i).LoadDurationCurve = load_duration_data(:,[1 sizingIdx+1]);

% Risk Analysis Results
final_results(i).RiskAnalysisResults = npv_at_risk(i);

% Cash flows
final_results(i).CashFlow = mean_cf(i,:);

% Generator Performance 
final_results(i).PowerGeneratorPerformance = power_generator_performance(sizingIdx);

% Incentives Required by profitability goals
final_results(i).IncentivesForProfit = incentives_for_profit(i);

% Sensitivity
final_results(i).sensitivity1_for_profit = sensitivity1_for_profit(i);

final_results(i).sensitivity2_for_profit = sensitivity2_for_profit(i);

final_results(i).sensitivity3_for_profit = sensitivity3_for_profit(i);

%% connections
tempTopology = [max(dist{dist{:, 2} < 0, 4}', 1 * ...
    (power_generator_performance(sizingIdx).RatedCapacity(1) > 0)), ...
    sitting_results(sittingIdx).topology];
connectionIdx = find(tempTopology > 0);
for j = 1:length(connectionIdx)
    final_results(i).pathConnections(j).id = dist{connectionIdx(j),5};
    final_results(i).pathConnections(j).cableType = 0;
    final_results(i).pathConnections(j).pipeSize = 0;
    final_results(i).pathConnections(j).(dist.Properties.VariableNames{4}) = tempTopology(connectionIdx(j));
end
%% tank & battery
    if financialGoals.systemType == "Micro Grid"
        final_results(i).energyExchangedTank = sizing_results(sizingIdx).power_generated(:, 11);
        final_results(i).energyExchangedBattery = sizing_results(sizingIdx).power_generated(:, 10);
    else
        final_results(i).energyExchangedTank = sizing_results(sizingIdx).power_generated(:, 16);
        final_results(i).energyExchangedBattery = 0;
    
    end
    
%% detailed cashflow
newTechs = sizing_results(sizingIdx).detailCost(1,:) ~= 0;
detailCostTable = array2table(sizing_results(sizingIdx).detailCost(:,newTechs), ...
    'VariableNames', techNames(newTechs), 'RowNames', ["Fixed Cost", "Maintenance Cost", "Operation(fuel) Cost"], ...
    'DimensionNames', ["Technologies", " "]);
% ["NGHW", "H2HW", "BMHW", "NG", "H2", "BM", "EA", "EW", "NGCHP", "H2CHP", "BMCHP", "NGB", "H2B", "BMB", "EB", "TES"]);
%"NGHW,H2HW,BMHW,NG,H2,BM,EA,EW,NGCHP,H2CHP,BMCHP,NGB,H2B,BMB,EB");
writetable(detailCostTable, "results_output/tempDetailCashFlow.csv", ...
    'WriteVariableNames',true, 'WriteRowNames', true);
writetable(table([], 'VariableNames', "---Cashflow Below---"), "results_output/tempDetailCashFlow.csv", ...
    'WriteVariableNames',true, 'WriteRowNames',false, "WriteMode", "append");
% writelines("Cashflow Below", "results_output/tempDetailCashFlow.csv", "WriteMode", "append");
detailCashFlowTable = table(round(sizing_results(sizingIdx).cash_flow'), round(sitting_results(sittingIdx).cash_flow'), ...
    round(cashflow_baseline(i,:)'), ...
    'VariableNames', ["sizing cash flow", "sitting cash flow", "baseline"]);
writetable(detailCashFlowTable, "results_output/tempDetailCashFlow.csv", ...
    'WriteVariableNames',true, 'WriteRowNames',false, "WriteMode", "append");
tempFile = fopen("results_output/tempDetailCashFlow.csv",'r');
final_results(i).detailCashFlow = fread(tempFile,'*char')';% char(fread(tempFile,'char*1'))';
fclose(tempFile);
end

end