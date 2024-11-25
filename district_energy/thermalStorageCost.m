function [installation, maintenance] = thermalStorageCost(capacity)
if capacity > 134654
    installation = 340091*log(capacity) - 3e6;
elseif capacity > 0
    installation = 7.4534*capacity+13000;
else
    installation = 0;
end
maintenance = capacity * 0.17; % averaged from 0.24 and 0.1