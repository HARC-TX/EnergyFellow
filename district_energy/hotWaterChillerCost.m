function [installation, maintenance] = hotWaterChillerCost(capacity)
capacityList = [0, 351.685, 703.37, 1055.055, 1406.74, 1758.425, 2110.11, 2461.795, 2813.48, 3165.165, 3516.85, 3516.85*100];
chillerCostList = [0, 150000, 241600, 287400, 356400, 402500, 483000, 543900, 544000, 598500, 665000, 665000*100];
installationCostList = [0, 150000, 301800, 359400, 534800, 604000, 724800, 1087800, 1088000, 1197000, 1329000, 1329000*100];
maintenanceCostList = [0, 10500, 11400, 12000, 13200, 13500, 13800, 14700, 16000, 16200, 17000, 17000*100];

installation = interp1(capacityList, chillerCostList + installationCostList, capacity, 'makima');
maintenance = interp1(capacityList, maintenanceCostList, capacity, 'makima');
end