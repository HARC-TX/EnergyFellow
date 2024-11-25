function [installation, maintenance] = waterElectricChillerCost(capacity)
capacityList = [0, 703.37, 1055.055, 1406.74, 1758.425, 2110.11, 2461.795, 2813.48, 3165.165, 3516.85, 3868.535, 3868.535*100];
chillerCostList = [0, 149000, 213900, 274400, 412000, 411600, 482300, 482400, 646200, 646000, 591800, 591800*100];
installationCostList = [0, 149000, 213900, 274400, 412000, 411600, 602700, 603200, 807300, 969000, 1065900, 1065900*100];
maintenanceCostList = [0, 11400, 12000, 13200, 13500, 13800, 14700, 16000, 15300, 18000, 19800, 19800*100];

installation = interp1(capacityList, chillerCostList + installationCostList, capacity, 'makima');
maintenance = interp1(capacityList, maintenanceCostList, capacity, 'makima');
end