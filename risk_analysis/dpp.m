function [dpp_value] = dpp(Netcash_Flow, financialGoals)

interestRate = financialGoals.interestRate;

downPayment = financialGoals.maximumDownPayment;
l = length(Netcash_Flow);
d_cf = zeros(1, l); %discounted cash flow
c_cf = zeros(1, l); %cumulative discounted cash flow
for i=1:l
    d_cf(i) = Netcash_Flow(i)/(1+interestRate)^(i-1);
end
for i=1:l
    c_cf(i) = sum(d_cf(1:i));
    if c_cf(i)>0
        y = i-1;
        break
    else
        y = i+1; 
    end 
end

if y<l && y > 0
dpp_value = (y-1) + (abs(c_cf(y))/d_cf(y+1));
else
dpp_value = 999; %if DPP>
end 
end



%end

