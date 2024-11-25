function [hydraulicPower, flowVelocity, totalPressureLoss] = pressureLoss(radius, demand, temperatureDiff, pipeLength)

type = "Turbulent";
% temperatureDiff = 6.13;
% radius = 0.25; flowVelocity = 2.26; pipeLength = 4500;

flowVelocity = demand./(997.*pi.*radius.^2.*temperatureDiff.*4.187);

Re = radius.*2.*997.*flowVelocity./0.00089; % Density of Fluid = 997, Dynamic Viscosity = 0.00089

roughness = 0.00005./radius./2; % Absolute Roughness = 0.00005
f0 = (1./(-1.*1.8.*log10((6.9./Re)+((roughness./3.71).^1.11)))).^2;
f1 = 1./((-1.*2.*log10(((2.51./Re).*(1./sqrt(f0)))+(roughness./3.71)))).^2;

f3 = 1./(-1.*2.*log10(((2.51./Re).*(1./sqrt(f1)))+(roughness./3.71))).^2;
if type == "Turbulent"
    pipePressureLoss = (0.5.*997.*flowVelocity.^2.*f3.*(pipeLength./radius./2));
else
    laminarFactor = 64./Re;
    pipePressureLoss = (0.5.*997.*flowVelocity.^2.*laminarFactor.*(pipeLength./radius./2));
end
minorLossCoeff = (0./radius.*2)*0; % Equivalent Length = 0, Darcy Friction Factor for component = 0
minorPressureLoss =0.5.*minorLossCoeff.*997.*flowVelocity.^2;
totalPressureLoss = pipePressureLoss + minorPressureLoss;
hydraulicPower = pi.*radius.^2.*flowVelocity.*totalPressureLoss./1000;