function [loan,cfLoan] = loan_CF(mean_cf, financialGoals)

interest_rate = financialGoals.interestRateLoan;
down_payment = financialGoals.maximumDownPayment;
loan_period = ceil(size(mean_cf,2)/2);
%Initializing loan and setting value to zero in case a loan is not needed.
cfLoan= zeros(1, size(mean_cf,2));
loan=0;
%Calculating if loan is needed and its CF
if abs(mean_cf(1,1))>down_payment
loan= mean_cf(1,1) + down_payment;
periodic_payment = payper(interest_rate, loan_period, loan);
cfLoan(1,1)=down_payment;
cfLoan(:,2:loan_period) = periodic_payment;
end
end