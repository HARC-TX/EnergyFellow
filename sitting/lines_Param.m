function [topoParam] = lines_Param(A, Dist,lines_data)

N = length(A);
R = zeros(N, 1);
X = zeros(N, 1);
Z = zeros(N, 1);
	
resistance = 1e-3 * lines_data.resistance;
reactance = 1e-3 * lines_data.reactance;
for i = 1:N
    
    if A(i) == 0
        R(i) = inf;
        X(i) = inf;
    else
    R(i) = resistance(A(i)) * Dist(i,3);%Resistance(Ohm/m)
    X(i) = reactance(A(i)) * Dist(i,3);%reactance(Ohm/m)
    end

end

Z = R + j * X;
Y = 1 ./ Z;

topoParam = Y;
end
