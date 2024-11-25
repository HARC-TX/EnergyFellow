function npv_at_risk = npv_risk(financialGoals, siting_risk_results, sizing_risk_results,baselineCashflowMC)

sitingLength = size(siting_risk_results.monte_carlo_cf, 2);
sizingLength = size(sizing_risk_results.monte_carlo_cf, 2);

for i = 1:max(sitingLength, sizingLength)
    sitingIdx = mod(i-1, sitingLength) + 1;
    sizingIdx = mod(i-1, sizingLength) + 1;
    netCF = siting_risk_results.monte_carlo_cf(sitingIdx).project_cost_cf + ...
            sizing_risk_results.monte_carlo_cf(sizingIdx).project_cost_cf - ...
            baselineCashflowMC(:,:,sitingIdx);
    % Calculation of NPV for MC results
    for j = 1:size(siting_risk_results.monte_carlo_cf(1).project_cost_cf, 1)
        npv_at_risk(i).NPV(j) = pvvar(netCF(j,:), financialGoals.interestRate);
        
        [npv_at_risk(i).irr(j), ~] = irr(netCF(j,:));
        npv_at_risk(i).dpp(j) = dpp(netCF(j,:), financialGoals);
    end

    % Finding min, max, mean, and median NPV
    npv_at_risk(i).varMin =   min((npv_at_risk(i).NPV));
    npv_at_risk(i).varMax =   max((npv_at_risk(i).NPV));
    npv_at_risk(i).varMean =   mean((npv_at_risk(i).NPV));
    
    npv_at_risk(i).pobs = length(find((npv_at_risk(i).NPV) > 0)) / j * 100;
    npv_at_risk(i).ioa90p = prctile(npv_at_risk(i).irr, 10) * 100;
    npv_at_risk(i).ioa90p(isnan(npv_at_risk(i).ioa90p)) = 0;
    npv_at_risk(i).duyya90p = prctile(npv_at_risk(i).dpp, 90);

end


end