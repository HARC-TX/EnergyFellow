function [hydrogenPrice, h2MTPD] = getH2Price(h2Consumption, h2Type)
% get hourly hydrogen price [hydrogenPrice] ($/kg) based on hourly
% consumption [h2Consumption] (kg) and type [h2Type] (grey, green, clean),
% MTPD of h2 is also output

h2MTPD = sum(reshape(h2Consumption, [24 365]))' ./ 1e3;

if h2Type == "green"
    % Green H2 with incentive
    dailyH2Price = (8.5589 .* (h2MTPD + 0.001) .^ (-0.225) - 0.6); % +0.001 to avoid inf results
else
    dailyH2Price = 10 .* ones(1, 365);
end

hydrogenPrice = reshape((dailyH2Price * ones(1,24))', [8760 1]);