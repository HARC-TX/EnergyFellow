function unitHeatLoss = unitConduitLoss(weather, financialGoals, T_s, T_r, pd)
% Function to calculate cooling/heating loss in both supply conduit and return conduit
% INPUT:
%   pd - (table) line 1 for supply, line 2 for return, if pd has only 1
%   line, it will be used for both supply and return
%
% OUTPUT:
%   out - (double) Calculated average of the three inputs

if size(pd,1) < 2
    pd(2,:) = pd(1,:);
end
% T_r = 12.8;
% T_s = 6.67;
T_soil = ones(8760,1) .* pd{1,"soilTemperature"};

theta_s = (T_r - T_soil) ./ (T_s - T_soil);

Ps = (1/(2*3.14*pd{1,"soilThermalConductivity"}))*log(sqrt((((pd{1,"pipeDepth"}+pd{1,"pipeDepth"})^2)+pd{1,"pipeDistance"}^2)/(((pd{1,"pipeDepth"}-pd{1,"pipeDepth"})^2)+pd{1,"pipeDistance"}^2)));
Pr = (1/(2*3.14*pd{2,"soilThermalConductivity"}))*log(sqrt((((pd{2,"pipeDepth"}+pd{2,"pipeDepth"})^2)+pd{2,"pipeDistance"}^2)/(((pd{2,"pipeDepth"}-pd{2,"pipeDepth"})^2)+pd{2,"pipeDistance"}^2)));


Rts = thermalResistance(pd(1,:));
Rtr = thermalResistance(pd(2,:));
Res = (Rts-(Ps.^2./Rtr)) ./ (1-((Ps.*theta_s)./Rtr));
Rer = (Rtr-(Pr.^2./Rts)) ./ (1-((Pr./theta_s)./Rts));

unitHeatLoss = ((T_s - T_soil)./Res + (T_r - T_soil)./Rer) ./1000; % W/m to KW/m

end

function R = thermalResistance(pd)
    pipe = log(pd.outerRadius/pd.innerRadius)/(2*pi()*pd.pipeThermalConductivity);
    insulation = (log((pd.outerRadius+pd.insulationThickness)/pd.outerRadius))/(2*pi()*pd.insulationThermalConductivity);
    if pd.pipeDepth / (pd.outerRadius + pd.insulationThickness) > 4
        soil = (log((2*pd.pipeDepth)/(pd.outerRadius+pd.insulationThickness)))/(2*pi()*pd.soilThermalConductivity);
    else
        soil = (log((pd.pipeDepth/(pd.outerRadius+pd.insulationThickness))+sqrt(((pd.pipeDepth/(pd.outerRadius+pd.insulationThickness))^2)-1)))/(2*pi()*pd.soilThermalConductivity);
    end
    R = pipe + insulation + soil;
end