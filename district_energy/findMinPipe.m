function minPipe = findMinPipe(totalLength, pd, demand, tempDiff)
% velocity of fluid < 3 m/s & pressure drop per m < 100 Pa/m.
[~, flowVelocity, totalPressureLoss] = pressureLoss(pd.innerRadius, demand, ...
    abs(tempDiff), totalLength);
minPipe = find(flowVelocity < 3 & (totalPressureLoss / totalLength) < 100, 1);