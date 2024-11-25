function [fixedCost] = costFixed(N, ~)

%% Ground Based Solar & Rooftop Solar & Grid
fixedCost = [N(1) * 1112.5, N(2) * 1511, zeros(1, 9), 0];
%% NG CHP
if N(3) > 0
    fixedCost(3) = 3e-5*N(3)^3 - 0.3968*N(3)^2 + 2805.5*N(3) + 57963;
end
%% H2 CHP
if N(4) > 0
    fixedCost(4) = interp1([115, 170, 250, 360, 750, 75000], ...
        [4.2e5, 5.36e5, 6.58e5, 8.08e5, 1.121e6, 1.121e8], N(4), 'makima') + (498.54 .* N(4) + 420770);
end
%% BM CHP PENDING
if N(5) > 0
    fixedCost(5) = 3e-5*N(5)^3 - 0.3968*N(5)^2 + 2805.5*N(5) + 57963;
end

%% NG Generator
if N(6) > 0
    fixedCost(6) = 0.061*N(6)^2 + 726.48*N(6) + 161.37;
end
%% Diesel Generator
if N(7) > 0
    fixedCost(7) = 5e-8*N(7)^4 - 3e-4*N(7)^3 + 0.4831*N(7)^2 + 220.66*N(7) + 40479;
end
%% H2 Generator
if N(8) > 0
    fixedCost(8) = interp1([115, 170, 250, 360, 750, 75000], ...
        [90449.50, 138594.87, 192917.88, 259760.98, 424504.57, 42450457], N(8), 'makima') + ...
        (0.0118 * N(8) ^ 2) + (168.88 * N(8)) + 18567;

end
%% BM Generator PENDING
if N(9) > 0
    fixedCost(9) = 0.061*N(9)^2 + 726.48*N(9) + 161.37;
end

%% Battery
if N(10) > 0
    fixedCost(10) = 476.21*N(10) + 12632;
end
%% Thermal Energy Storage
if N(11) > 134654
    fixedCost(11) = 340091*log(N(11)) - 3e6;
elseif N(11) > 0
    fixedCost(11) = 7.4534*N(11) + 13000;
end

end