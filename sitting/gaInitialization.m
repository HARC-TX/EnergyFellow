function [population,m]= gaInitialization(nbus, ncables, M)
m = 0;
while m < M
    [vect_connection] = generateConnection(nbus, ncables);
    if isLegitConnection(vect_connection, nbus)
        m = m + 1;
        population(m).Gene(:) = vect_connection;
    end
end