function [fixedCost, cLC, cSub] = cost_fixed(LinesData, X, dist, power_load)

cableType = X(X > 0);
cableLength = dist(X > 0);
cPl = 0;
for i = 1:length(cableType)
    cPl = cPl + LinesData.fixed(cableType(i)) * cableLength(i);
end

cSub = interp1([5e2, 2e3, 5e3, 1e4, 1e5, 2e5], ...
    [2.5e4, 1e5, 7e5, 1.35e6, 1.535e7, 1.535e7 * 2], max(sum(power_load, 2)), 'makima');

xLC = [25, 50, 75, 100, 112.5, 150, 225, 300, 500, 750, 1000, 1500, 2500];
vLC = [5722, 6419, 8032, 6021, 8337, 34232, 49300, 37195, 45358, 52751, 77410, 105000, 159500];
cLC = sum(interp1(xLC,vLC,max(power_load),'makima'));

fixedCost = cPl + cSub + cLC;
end