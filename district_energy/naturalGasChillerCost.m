function [installation, maintenance] = naturalGasChillerCost(capacity)
capacityList = [0, 351.685, 703.37, 1055.055, 1406.74, 1758.425, 2110.11, 2461.795, 2813.48, 3165.165, 3516.85, 3516.85 *100];
chillerCostList = [0, 230000, 386400, 455400, 523200, 575000, 712800, 830200, 955200, 948600, 949000, 949000*100];
installationCostList = [0, 230000, 483000, 569400, 784800, 862500, 1069800, 1245300, 1909600, 1897200, 1898000, 1898000*100];
maintenanceCostList = [0, 12000, 13000, 13500, 14800, 15500, 15600, 16800, 16800, 17100, 18000, 18000*100];

installation = interp1(capacityList, chillerCostList + installationCostList, capacity, 'makima');
maintenance = interp1(capacityList, maintenanceCostList, capacity, 'makima');
end