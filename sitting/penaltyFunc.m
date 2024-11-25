function [pen] =  penaltyFunc(S1, Lim, idx, X, FT)

m = length(FT(:,1));
S = zeros(2*m,1);
for j = 1:m
    S(j) = S1(FT(j,1),FT(j,2));
    for k = m+1:2*m
         S(k) = S1(FT(j,2),FT(j,1));
    end
end
pen = 1;
c = 1e7;

for i = 1:length(idx)
    if abs(S(i)) >= Lim(X(idx(i)))
        pen = c * pen;
    else
        pen = 0;
    end

end
end