function [installation, maintenance] = naturalGasBoilerCost(capacity)
capacityList = [0, 300, 500, 700, 900, 1100, 1300, 1500, 1700, 1900, 2100, 2300, 2500, 2700, 2900, 2900*100];
bolierCostList = [0, 35000, 41500, 48000, 60000, 67000, 72000, 78000, 85000, 98000, 105000, 112000, 120000, 128000, 135000, 135000*100];
installationCostList = [0, 25000, 28000, 32000, 35000, 40000, 42000, 45000, 48000, 50000, 53000, 56000, 60000, 62000, 65000, 65000*100];

installation = interp1(capacityList, bolierCostList + installationCostList, capacity, 'makima');
maintenance = 0;%((capacity*3412.142*1.25*4*0.6*24*30)/1000000)*0.15*12;
end