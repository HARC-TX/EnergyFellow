function [siting_risk_results] = siting_risk_analysis(siting_solution,prob_table, fuel_table)

%capital
cost_cap=prob_table(:,9);
%maintenance
cost_maint=prob_table(:,10);
%replacement
cost_rep=prob_table(:,11);
%salvage
cost_salvg=prob_table(:,12);

for i = 1:size(siting_solution,2)

    % MC Simulation of cost related parameters
    risk_capital_cost_cf       = cost_cap .* siting_solution(i).capital_cost;
    risk_maintenance_cost_cf   = cost_maint .* siting_solution(i).maintenance_cost;
    risk_replacement_cost_cf   = cost_rep .* siting_solution(i).replacement_cost;
    risk_salvage_cost_cf       = cost_salvg .* siting_solution(i).salvage_cost;
    risk_power_loss_cost_cf    = [zeros(size(fuel_table.electricity,1),1),...
      fuel_table.electricity] .* siting_solution(i).power_loss_cost;
    
    siting_risk_results.monte_carlo_cf(i).capital_cost_cf      =  risk_capital_cost_cf(:, 1);
    siting_risk_results.monte_carlo_cf(i).maintenance_cost_cf  =  risk_maintenance_cost_cf;
    siting_risk_results.monte_carlo_cf(i).replacement_cost_cf  =  risk_replacement_cost_cf;
    siting_risk_results.monte_carlo_cf(i).salvage_cost_cf      =  risk_salvage_cost_cf(:, end);
    siting_risk_results.monte_carlo_cf(i).power_loss_cost_cf   =  risk_power_loss_cost_cf;
    
    siting_risk_total_cf = (risk_capital_cost_cf + risk_maintenance_cost_cf...
                             + risk_replacement_cost_cf + risk_salvage_cost_cf);  

    siting_risk_results.monte_carlo_cf(i).project_cost_cf = siting_risk_total_cf;

    siting_risk_results.average_cf(i).mean_cash_flow = mean(siting_risk_total_cf);
end

end