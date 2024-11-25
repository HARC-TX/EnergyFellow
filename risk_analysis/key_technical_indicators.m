function tech_results = key_technical_indicators(sizing_results, sizing_risk_results, financialGoals, tech_data)

%% Conversion data
environmental_coeff = tech_data.cotwo_emission';
environmental_coeff = environmental_coeff(~isnan(environmental_coeff));

fuel_coeff = tech_data.fuel_coefficient';
fuel_coeff = fuel_coeff(~isnan(fuel_coeff));

fuel_conv = tech_data.fuel_converting_table';
fuel_conv = fuel_conv(~isnan(fuel_conv));


if financialGoals.systemType == "Micro Grid"
    for i = 1:size(sizing_results,2)
        tech_results(i).demand = [1, 1] .* sum(sum(sizing_results(i).power_load));
        power_generation = sizing_results(i).power_generated;
        energy_generation(i) = sum(power_generation(:,1:9), 'all');
        renewable_generation(i) = sum(power_generation(:,1:2), 'all');
        annual_fuel_capacity(i,:) = sizing_results(i).annualFuel ...
            .* [1, 42.55157, 1, 1, 40.2624/3.78541, 42.55157, 1, 1, 1, 1]; % fuel consumption in kwh
        % 40.2624 kwh/gallon for diesel in thermal
        
        tech_results(i).generatedOnsite = [0, sum(power_generation(:,1:9), 'all')];
        tech_results(i).fromUtility = [tech_results(i).demand(1), sum(power_generation(:,12))];
        
        tech_results(i).naturalGasConsump = [0, sum(annual_fuel_capacity(i,[1 4]))];
        tech_results(i).dieselConsump = [0, sum(annual_fuel_capacity(i,5)) / 40.2624 * 3.78541];
        tech_results(i).hydrogenConsump = [0, sum(annual_fuel_capacity(i,[2 6])) / 42.55157];
        % diesel 10.21 kg of co2/gallon
        tech_results(i).environEmission = [tech_results(i).demand(1) * 0.349756, ...
            tech_results(i).naturalGasConsump(2) / 293.07107 * 53.06 ...
            + tech_results(i).dieselConsump(2) / 3.78541 * 10.21 ...
            + tech_results(i).hydrogenConsump(2)  * 2.982 ...
            + sum(power_generation(:,12)) * 0.349756];
        tech_results(i).netEnvironEmission = [0, 0];
        
        if energy_generation(i) ~= 0
            tech_results(i).renewableFraction = [0, 100 * (renewable_generation(i)/ energy_generation(i))];
            tech_results(i).OnsiteFuelToPowerEff = [0, 100 * (sum(annual_fuel_capacity(i, 1:9)) /  energy_generation(i))];
            tech_results(i).lcoe = [0, abs(sizing_risk_results.average_cf(i).mean_cash_flow(1,1))/energy_generation(i)];
            tech_results(i).breakEvenPoint = [0, (financialGoals.electricityPrice * tech_results(i).demand(2))/tech_results(i).lcoe(2)];
        else
            tech_results(i).renewableFraction = [0, 0];
            tech_results(i).OnsiteFuelToPowerEff = [0, 0];
            tech_results(i).lcoe = [0, 0];
            tech_results(i).breakEvenPoint = [0, 0];
        end
        
        if sum(annual_fuel_capacity(i,1:9)) ~=0
            capacities = sizing_results(i).optimal_size;
            tech_results(i).energyToFuelRatio = [0, (energy_generation(i) + sum( ...
                [CHPthermal(capacities(3),"NG")*sum(power_generation(:,3))/capacities(3), ...
                CHPthermal(capacities(4),"H2")*sum(power_generation(:,4))/capacities(4), ...
                CHPthermal(capacities(5),"BM")*sum(power_generation(:,5))/capacities(5)], "omitnan"))...
                / sum(annual_fuel_capacity(i,1:9)) * 100];
        else
            tech_results(i).energyToFuelRatio = [0, 0];
        end
    end
else
    for i = 1:size(sizing_results,2)
        tech_results(i).demand = [1, 1] .* sum(sizing_results(i).thermal_load);
        
        tech_results(i).generatedOnsite = [0, -sum(sizing_results(i).techData.electricityConsumption(:, [1:3, 9:11]), "all")];
        
        tech_results(i).fromUtility = [0, sum([sizing_results(i).techData.electricityConsumption(:, [4:8, 12:15]), ...
            sizing_results(i).techData.pumpLoad], "all")- tech_results(i).generatedOnsite(2)];
            
        tech_results(i).naturalGasConsump = [0, sum(sizing_results(i).techData.fuelConsumption(:, [1,4,9,12]), "all")];
        tech_results(i).dieselConsump = [0, 0];
        tech_results(i).hydrogenConsump = [0,  sum(sizing_results(i).techData.fuelConsumption(:, [2,5,10,13]), "all")];
        
        % NG 0.18053 kg of co2/kwh from epa, Electricity 0.349756 kg of co2/kwh, 10.729 kwh/m3 of natural gas from EIA(2022)
        % H2 use GREEN H2, 2.982 kg of co2/kg of H2
        tech_results(i).environEmission = [0,...
            tech_results(i).naturalGasConsump(2) / 293.07107 * 53.06 ...
            + tech_results(i).hydrogenConsump(2) * 2.982 ...
            + sum(sizing_results(i).techData.electricityConsumption(:, [4:8,12:15]), "all") * 0.349756];
        if financialGoals.systemType == "District Cooling"
            tech_results(i).fromUtility(1) = tech_results(i).demand(1) / mean(financialGoals.chillerEfficiency);
            tech_results(i).environEmission(1) = 0.39089 * tech_results(i).demand(1) / mean(financialGoals.chillerEfficiency);
        else
            tech_results(i).naturalGasConsump(1) = tech_results(i).demand(1) / mean(financialGoals.boilerEfficiency);
            tech_results(i).environEmission(1) = 0.18053 .* tech_results(i).demand(1) / mean(financialGoals.boilerEfficiency);
        end
        
        tech_results(i).netEnvironEmission = [tech_results(i).environEmission(1), ...
            tech_results(i).environEmission(2) + ...
            sum(sizing_results(i).techData.electricityConsumption(:, [1,2,3,9,10,11]), "all") * 0.349756];

        tech_results(i).renewableFraction = [0, 0];
        tech_results(i).OnsiteFuelToPowerEff = [0, 0];
        tech_results(i).energyToFuelRatio = [0, 0];
        
        tech_results(i).lcoe = [0, abs(sizing_risk_results.average_cf(i).mean_cash_flow(1,1))/sum(sizing_results(i).thermal_load)];
        tech_results(i).breakEvenPoint = [0, sum(sizing_results(i).power_cost(17:32))/tech_results(i).lcoe(2)];
    end
end

end