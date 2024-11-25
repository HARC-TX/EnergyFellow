function [installation, maintenance] = electricityBoilerCost(capacity)
capacityList = [0, 300, 500, 700, 900, 1100, 1300, 1500, 1700, 1900, 2100, 2300, 2500, 2700, 2900, 2900*100];
installationCostList = [0, 20000, 22000, 25000, 28000, 32000, 33000, 36000, 38000, 40000, 42000, 44000, 48000, 49000, 52000, 52000*100];

installation = capacity * 120 + interp1(capacityList, installationCostList,capacity,'makima');
maintenance = 0;
end