function load_duration_curve = load_duration(sizing_results)

%Aux2=[500 1000 1500 2000 2500 3000 3500 4000 4500 5000 5500 6000 6500 7000 7500 8000 8500 8760]';
curveLength = max(size(sizing_results(1).power_load,1), size(sizing_results(1).thermal_load,1));
load_duration_curve = zeros(curveLength,size(sizing_results,2)+1);
load_duration_curve(:,1) = (1:curveLength);

for i = 1:size(sizing_results,2)
    if isempty(sizing_results(i).power_load)
        load = sum(sizing_results(i).thermal_load,2);
    else
        load = sum(sizing_results(i).power_load,2);
    end
    Aux3=sort(load,'descend');
    load_duration_curve(:,i+1)=Aux3;
end

end