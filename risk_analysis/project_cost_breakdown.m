function project_costs =  project_cost_breakdown(siting_risk_results, sizing_risk_results)

sitingLength = size(siting_risk_results.monte_carlo_cf, 2);
sizingLength = size(sizing_risk_results.monte_carlo_cf, 2);

for i = 1:max(sitingLength, sizingLength)
    sitingIdx = mod(i-1, sitingLength) + 1;
    sizingIdx = mod(i-1, sizingLength) + 1;
    capital_cost      = mean(siting_risk_results.monte_carlo_cf(sitingIdx).capital_cost_cf...
                        + sizing_risk_results.monte_carlo_cf(sizingIdx).capital_cost_cf);

    maintenance_cost  = sum(mean(siting_risk_results.monte_carlo_cf(sitingIdx).maintenance_cost_cf...
                        + sizing_risk_results.monte_carlo_cf(sizingIdx).maintenance_cost_cf));

    replacement_cost  = sum(mean(siting_risk_results.monte_carlo_cf(sitingIdx).replacement_cost_cf...
                        + sizing_risk_results.monte_carlo_cf(sizingIdx).replacement_cost_cf));
    operation_cost    = sum(mean(sizing_risk_results.monte_carlo_cf(sizingIdx).operation_cost_cf));

    project_costs(i).initialProjectCost = abs(capital_cost(1));
    project_costs(i).maintenance = abs(maintenance_cost);
    project_costs(i).systemReplacement = abs(replacement_cost);
    project_costs(i).service = abs(operation_cost);

end

end