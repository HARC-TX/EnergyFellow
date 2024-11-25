function [keyFinancialIndicators] = key_financial_indicators(mean_cf, financialGoals,cashflow_baseline,PV_baseline)

Netcash_flow=zeros(size(mean_cf,1), size(mean_cf,2));
cashflow_loan=zeros(size(mean_cf,1), size(mean_cf,2));

for i = 1:size(mean_cf,1)
    % Cash flows
    [ loan, cashflow_loan(i,:)] =  loan_CF(mean_cf(i,:), financialGoals);
    Netcash_flow(i,:) = mean_cf(i,:) + cashflow_loan(i,:) - cashflow_baseline(i,:);
    
    % Key economic indicators
    keyFinancialIndicators(i).loan = abs(loan);
    keyFinancialIndicators(i).NPV = pvvar(Netcash_flow(i,:), financialGoals.interestRate);
    keyFinancialIndicators(i).DPP = dpp(Netcash_flow(i,:),financialGoals);
    %[keyFinancialIndicators(i).loan, ~] =loan_CF(mean_cf(i,:), financialGoals); 
    keyFinancialIndicators(i).annual_savings = annual_savings(mean_cf(i,:), cashflow_baseline(i,:));
    keyFinancialIndicators(i).initial_investment = -mean_cf(i,1);
    [keyFinancialIndicators(i).IRR, ~] = irr(Netcash_flow(i,:));
    if isnan(keyFinancialIndicators(i).IRR)
        keyFinancialIndicators(i).IRR = 0;
    else
        keyFinancialIndicators(i).IRR = keyFinancialIndicators(i).IRR * 100;
    end
    keyFinancialIndicators(i).equivalent_annuity = payuni(Netcash_flow(i,2:end), financialGoals.interestRate);
end

