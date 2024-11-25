function annual_saving = annual_savings(mean_cf, cashflow_baseline )

n = ceil((size(mean_cf,2))/2);

annual_saving = mean_cf(1, n+3) - cashflow_baseline(1, n+3);

end