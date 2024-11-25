function [sizing_risk_results] = sizing_risk_analysis(sizing_solution, prob_table, fuel_table,financialGoals)

%capital
cost_cap=prob_table(:,9);
%maintenance
cost_maint=prob_table(:,10);
%replacement
cost_rep=prob_table(:,11);
%salvage
cost_salvg=prob_table(:,12);
% 
% life_project = numel(sizing_solution.Chromosomes(1).cash_flow);
% zero_fuel_table = zeros(size(fuel_table.electricity));

for i = 1:size(sizing_solution,2)

    % MC Simulation of cost related parameters
    risk_capital_cost_cf       = cost_cap .* sizing_solution(i).capital_cost;
    risk_maintenance_cost_cf   = cost_maint .* sizing_solution(i).maintenance_cost;
    risk_replacement_cost_cf   = cost_rep .* sizing_solution(i).replacement_cost;
    risk_salvage_cost_cf       = cost_salvg .* sizing_solution(i).salvage_cost;
if financialGoals.systemType == "Micro Grid"
    risk_operation_cost_cf    = -[zeros(size(fuel_table.electricity,1),1),...
      sum(sizing_solution(i).power_cost([3 6])) .* fuel_table.naturalGas +...
      sum(sizing_solution(i).power_cost([4 8])) .* fuel_table.hydrogen +...
      sum(sizing_solution(i).power_cost([5 9])) .* fuel_table.biomass +...
      sizing_solution(i).power_cost(7) .* fuel_table.diesel +...
      sizing_solution(i).power_cost(12) .* fuel_table.electricity];
else
    risk_operation_cost_cf    = -[zeros(size(fuel_table.electricity,1),1),...
      sum(sizing_solution(i).power_cost([17 20 25 28])) .* fuel_table.naturalGas + ...
      sum(sizing_solution(i).power_cost([18 21 26 29])) .* fuel_table.hydrogen + ...
      sum(sizing_solution(i).power_cost([19 22 27 30])) .* fuel_table.biomass + ...
      sum(sizing_solution(i).power_cost(1:16)) .* fuel_table.electricity];
end
    
    sizing_risk_total_cf = (risk_capital_cost_cf + risk_maintenance_cost_cf...
                             + risk_replacement_cost_cf + risk_salvage_cost_cf + risk_operation_cost_cf);  

    sizing_risk_results.monte_carlo_cf(i).project_cost_cf      = sizing_risk_total_cf;
    sizing_risk_results.monte_carlo_cf(i).capital_cost_cf      =  risk_capital_cost_cf(:, 1);
    sizing_risk_results.monte_carlo_cf(i).maintenance_cost_cf  =  risk_maintenance_cost_cf;
    sizing_risk_results.monte_carlo_cf(i).replacement_cost_cf  =  risk_replacement_cost_cf;
    sizing_risk_results.monte_carlo_cf(i).salvage_cost_cf      =  risk_salvage_cost_cf(:, end);
    sizing_risk_results.monte_carlo_cf(i).operation_cost_cf    =  risk_operation_cost_cf;

    mean_cf = mean(sizing_risk_total_cf);
    sizing_risk_results.average_cf(i).mean_cash_flow = mean_cf;

end
end