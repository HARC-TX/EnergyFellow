function gen_perf = power_generators_performance(sizing_results, techNames, tech_data, financialGoals)

% Conversion data
environmental_coeff = tech_data.cotwo_emission';
environmental_coeff = environmental_coeff(~isnan(environmental_coeff));

fuel_coeff = tech_data.fuel_coefficient';
fuel_coeff = fuel_coeff(~isnan(fuel_coeff));

fuel_conv = tech_data.fuel_converting_table';
fuel_conv = fuel_conv(~isnan(fuel_conv));

life_span = tech_data.replacement_cost1';
life_span = life_span(~isnan(life_span));

for i = 1:size(sizing_results,2)
    gen_perf(i).techNames = techNames;
    
    power_generation = sizing_results(i).power_generated;
    capacities = sizing_results(i).optimal_size;
    
    % Capacities
    gen_perf(i).RatedCapacity   =  capacities;
    gen_perf(i).MaxCapacity     =  ceil(max(power_generation));
    gen_perf(i).AverageCapacity =  ceil(mean(power_generation ./ (power_generation ~= 0), "omitnan"));
    gen_perf(i).AverageCapacity(isinf(gen_perf(i).AverageCapacity) | isnan(gen_perf(i).AverageCapacity)) = 0;
    
    % Operating hours
    gen_perf(i).OperatingHours  =  sum(power_generation ~= 0);
    
    % Start times
    Starts=zeros(1,size(power_generation,2));
    Aux1=[];
    Aux1=(power_generation > 0);
    for g=1:size(Aux1,2)
        for n=2:size(Aux1,1)
            if Aux1(n,g)>Aux1(n-1,g)
                Starts(g)=Starts(g)+1;
            end
        end
    end
    gen_perf(i).Starts=Starts;
    
if financialGoals.systemType == "Micro Grid"
    gen_perf(i).Lifespan  =  life_span ./ ...
        [(gen_perf(i).OperatingHours(1:2) > 0 ) * 8760, gen_perf(i).OperatingHours(3:12)];
    
    % Energy generated
    gen_perf(i).EnergyGenerated  = [sum(power_generation(:,1:10)), 0,  sum(power_generation(:,12))];
    
    % Thermal Output
    gen_perf(i).ThermalOutput = [ 0 .* sum(power_generation(:,1:2)),...
        CHPthermal(capacities(3),"NG")*sum(power_generation(:,3))/capacities(3),...
        CHPthermal(capacities(4),"H2")*sum(power_generation(:,4))/capacities(4),...
        CHPthermal(capacities(5),"BM")*sum(power_generation(:,5))/capacities(5),...
        0,0,0,0,0 * sum(power_generation(:,10:12))];
    
    % Electricity Consumption
    gen_perf(i).ElectricityConsumption = zeros(1,12);
    
    % Fuel
    gen_perf(i).FuelCapacity = [0, 0, sizing_results(i).annualFuel ...
            .* [1, 42.55157, 1, 1, 40.2624/3.78541, 42.55157, 1, 1, 1, 0]]; % fuel consumption in kwh
        % 40.2624 kwh/gallon for diesel in thermal
    
    % Electrical Efficiency
    gen_perf(i).Efficiency  = [100 *  (gen_perf(i).EnergyGenerated(1:11)) ./ (gen_perf(i).FuelCapacity(1:11)), 0];
    
    % Environmental Emissions
    gen_perf(i).EnvEmissions = gen_perf(i).FuelCapacity .* ...
        [1, 1, 53.06/293.07107, 2.98/42.551572, 1, 53.06/293.07107, 10.21/40.2624, 2.98/42.551572, 1, 1, 1, 0.349756];
else
    % Lifespan based on operating hours
    life_span = 175200 .* ones(1,16);
    gen_perf(i).Lifespan  =  life_span ./ gen_perf(i).OperatingHours;
    
    % Energy generated
    energy = [sum(sizing_results(i).techData.electricityConsumption(:, 1:15),1), 0];
    gen_perf(i).EnergyGenerated  = -min(energy,0);
    
    % Thermal Output
    gen_perf(i).ThermalOutput = [sum(power_generation(:,1:15)), 0];
    
    % Electricity Consumption
    gen_perf(i).ElectricityConsumption = max(energy,0);
    
    % Fuel 10.729 kwh/m3 of natural gas from EIA(2022), 42.551572 kwh/kg of hydrogen
    % Fuel consumption in kwh for NGHW, H2HW, BMHW, NG, H2, BM, EA, EW, NGCHP, H2CHP, BMCHP, NGB, H2B, BMB, EB
    gen_perf(i).FuelCapacity = [sum(sizing_results(i).techData.fuelConsumption(:, 1:15),1) .* ...
        [1, 42.55157, 1, 1, 42.55157, 1, 1, 1, 1, 42.55157, 1, 1, 42.55157, 1, 1], 0];
    
    % Electrical Efficiency
    gen_perf(i).Efficiency  = [(gen_perf(i).ThermalOutput(1:15) + gen_perf(i).EnergyGenerated(1:15))...
        ./ (gen_perf(i).ElectricityConsumption(1:15) + gen_perf(i).FuelCapacity(1:15)) .* [ones(1,8),100 .* ones(1,7)], 0];
    
    % Environmental Emissions
    gen_perf(i).EnvEmissions = gen_perf(i).FuelCapacity .* ...
        [53.06/293.07107, 2.98/42.551572, 1, 53.06/293.07107, 2.98/42.551572, 1, ...
        0.349756, 0.349756,53.06/293.07107, 2.98/42.551572, 1, 53.06/293.07107, 2.98/42.551572, 1, 0.349756, 0] + ...  % Biomass PENDING 
    	 + 0.349756 * gen_perf(i).ElectricityConsumption;
    
    
end
    gen_perf(i).Lifespan(isinf(gen_perf(i).Lifespan)|isnan(gen_perf(i).Lifespan)) = 999;
    gen_perf(i).ThermalOutput(isinf(gen_perf(i).ThermalOutput)|isnan(gen_perf(i).ThermalOutput)) = 0;
    gen_perf(i).Efficiency(isinf(gen_perf(i).Efficiency)|isnan(gen_perf(i).Efficiency)) = 0;
    
end


end