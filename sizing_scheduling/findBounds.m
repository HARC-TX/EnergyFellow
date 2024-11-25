function [minBound, maxBound] = findBounds(tech_data, financialGoals, tot_power_load, thermal_load, state_tech,SolarMatrix,solarProdMatrix)

MaxP = max(tot_power_load);
maxBound = zeros(size(state_tech));
minBound = zeros(size(state_tech));

%% Ground Based Solar
if (state_tech(1) == 1)
    maxBound(1) =  ceil(min(2 * MaxP, sum(solarProdMatrix(:,3))));
end
%% Rooftop Solar
if (state_tech(2) == 1)
    maxBound(2) =  ceil(min(2 * MaxP, sum([SolarMatrix.capacity] .* [SolarMatrix.includeSolar])));
end
%% NG CHP
if (state_tech(3) == 1)
    maxBound(3) = ceil(CHPelectric(prctile(thermal_load, 25), "NG") / 0.2);
end
%% H2 CHP
if (state_tech(4) == 1)
    maxBound(4) = ceil( CHPelectric(prctile(thermal_load, 25), "H2") / 0.2);
end
%% BM CHP
if (state_tech(5) == 1)
    maxBound(5) = ceil(CHPelectric(prctile(thermal_load, 25), "BM") / 0.2);
end
%% NG Generator
if (state_tech(6) == 1)
    maxBound(6) = ceil(MaxP * 1.2);%
end
%% Diesel Generator
if (state_tech(7) == 1)
    maxBound(7) = ceil(MaxP * 1.2);%
end
%% H2 Generator
if (state_tech(8) == 1)
    maxBound(8) = ceil(MaxP * 1.2);
end
%% BM Generator
if (state_tech(9) == 1)
    maxBound(9) = ceil(MaxP * 1.2);%
end
%% Battery
if (state_tech(10) == 1)
    maxBound(10) = ceil(prctile(movsum(tot_power_load, ...
        max(financialGoals.resilienceGoalTime * 2, 168 - any(state_tech([3 4 5 8])) * 156)), 100));
end
%% Thermal Energy Storage
if (state_tech(11) == 1)
    maxBound(11) = ceil(prctile(movsum(thermal_load, 168), 100));
end
%% Grid
if (state_tech(12) == 1)
    maxBound(12) = ceil(MaxP);% ceil((2.5 * MaxP) / cap_Grid);
end


end