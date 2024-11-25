function [mainCost] = cost_maintenance(LinesData, X, dist, power_load)

cableType = X(X > 0);
cableLength = dist(X > 0);
cPlM = 0;
for i = 1:length(cableType)
    cPlM = cPlM + LinesData.maintenance(cableType(i)) * cableLength(i);
end

cSubM = LinesData.cost_main_subs(1) * max(sum(power_load, 2));
cLCM = sum(LinesData.cost_main_lc(1) *max(power_load));

mainCost = cPlM + cSubM + cLCM;
end