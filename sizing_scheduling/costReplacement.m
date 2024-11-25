function [cfReplacement,replacementCost, flag] = costReplacement(singleReplacementCost, replacePeriod, D, lifeCycle)   

n = length(singleReplacementCost);
lifeCycle([1,2,end]) = (lifeCycle([1,2,end]) > 0) .* 8760;
flag = max(ceil(D * lifeCycle(1:n) ./ replacePeriod(1:n) - 1),0);

replacementCost = flag .* singleReplacementCost;
cfReplacement = zeros(n, D+1);
replaceInteval = replacePeriod(1:n) ./lifeCycle(1:n);
for i = 1:n
    if replaceInteval(i) < D && replaceInteval(i) > 0
        replaceYear = floor(replaceInteval(i):replaceInteval(i):D) + 1;
        cfReplacement(i, replaceYear(replaceYear <= D) + 1) = -singleReplacementCost(i);
    end
end
end 