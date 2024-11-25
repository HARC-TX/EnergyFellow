function [maintenanceCost] = costMaintenance(N)

gbPV = N(1) * 20;
rtPV = N(2) * 17;
battery = N(6) * 11.993 + 317.59 * (N(6) > 0);
tank = N(7) * 0.17; % averaged from 0.24 and 0.1
maintenanceCost = [gbPV, rtPV, zeros(1,7), battery, tank, 0];

end