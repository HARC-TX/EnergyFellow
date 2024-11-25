function fuel_table = calcul_fuel(financialGoals, caseCount)

lifespan = 0:financialGoals.lifespan-1;

fuel_table.naturalGas = (1 + financialGoals.naturalGasPriceEscalation/100.*...
    prob_generator(financialGoals.naturalGasDeterminationMethod, 0.05, caseCount)) .^ lifespan;

fuel_table.hydrogen = (1 + financialGoals.hydrogenPriceEscalation/100.*...
    prob_generator(financialGoals.hydrogenDeterminationMethod, 0.05, caseCount)) .^ lifespan;

fuel_table.biomass = (1 + financialGoals.biomassPriceEscalation/100.*...
    prob_generator(financialGoals.biomassDeterminationMethod, 0.05, caseCount)) .^ lifespan;

fuel_table.diesel = (1 + financialGoals.dieselPriceEscalation/100.*...
    prob_generator(financialGoals.dieselDeterminationMethod, 0.05, caseCount)) .^ lifespan;

fuel_table.electricity = (1 + financialGoals.electricityPriceEscalation/100.*...
    prob_generator(financialGoals.electricityDeterminationMethod, 0.05, caseCount)) .^ lifespan;

function prob_case = prob_generator(probType, probStd, caseCount)
if strcmpi(probType,'Triangle')
        prob_case= 1-probStd + (probStd+probStd)*rand(caseCount,1); %VARIATION triangular
else
        prob_case = random('Normal',1,probStd,caseCount,1);
end
    