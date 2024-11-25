function [salvageCost] = costSalvage(fixedCost, replacePeriod, D, lifeCycle)

n = length(fixedCost);
lifeCycle(1:2) = (lifeCycle(1:2) > 0) .* 8760;
flag = 1-rem(D * lifeCycle(1:n) ./ replacePeriod(1:n),1);
flag(flag==1) = 0;
salvageCost = flag' .* fixedCost;
end