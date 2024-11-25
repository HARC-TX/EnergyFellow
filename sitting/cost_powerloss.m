function [lossCost, PGen, Pij, Qij,PLoss_ij, QLoss_ij] = cost_powerloss ...
    (LinesData, X, dist, power_load, hour_price, nbus, voltage)
[Y, FT] = yBus(X, dist, nbus, LinesData);
X1 = X;
X(X>=1) = 1;
FT = FT .* X;
idx = find(FT(:,1) > 0);
FT = [FT((idx),1) FT((idx),2)];

[V, del,PLoad, PLoss, Pij, Qij,  PLoss_ij,  QLoss_ij, lossCost, conv_flag] = pfa(Y, power_load, FT, hour_price, nbus);

Lim = LinesData.ampacity * voltage * 1.732;
PGen = PLoad' + PLoss';
S = Pij / 0.95;

lossCost2 = sum(lossCost);

penalty =  penaltyFunc(S, Lim, idx, X1, FT);

lossCost = lossCost2 + penalty;

end