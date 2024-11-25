function incentives_for_profit = incentives_for_profitability(mean_cf, financialGoals,cashflow_baseline)

TempPaybackGoal=financialGoals.paybackGoal;
Netcashflow = mean_cf - cashflow_baseline(size(mean_cf, 1), :);
for i = 1:size(Netcashflow,1)
%% IcntvIRRgoal
   [IRRNetCF, ~]=irr(Netcashflow(i,:));
    if IRRNetCF>0 && IRRNetCF-financialGoals.irr_goal<0 % Si el IRR es menor que el deseado calculo correccion CF
    CIRR0=Netcashflow(i,1);
    CIRRgoal=-mean(Netcashflow(i,2:end))*(((1+financialGoals.irr_goal)^financialGoals.lifespan)-1)/((financialGoals.irr_goal)*(1+financialGoals.irr_goal)^financialGoals.lifespan);
    IncntvIRR=CIRRgoal-CIRR0;
    else
        if IRRNetCF>0
        IncntvIRR=0;
        else
        IncntvIRR=999;
        end
    end
    incentives_for_profit(i).incentive_for_irr= IncntvIRR;
%% IncntvDPPgoal
    %Calculate DNetcashflow
    s=0:financialGoals.lifespan;
    DNetcashflow=Netcashflow(i,:)./power((1+financialGoals.interestRate),s);
    IncntvDPP=sum(DNetcashflow);
    if IncntvDPP>0
        IncntvDPP=0;
    end
    if (Netcashflow(i,1))>IncntvDPP
     IncntvDPP=-999;
    end
    % IncntvDPP(IncntvDPP>=0)=0;
    incentives_for_profit(i).incentive_for_dpp = -IncntvDPP;
%% Savings to IRRgoal
    AnnIRR0=mean(Netcashflow(i,2:end));
    AnnIRRgoal=-Netcashflow(i,1)/((((1+financialGoals.irr_goal)^financialGoals.lifespan)-1)/((financialGoals.irr_goal)*(1+financialGoals.irr_goal)^financialGoals.lifespan));
    SavingsIRR=AnnIRRgoal-AnnIRR0;
    incentives_for_profit(i).additional_annual_savings_irr = max(SavingsIRR, 0);
%% Savings to DPPgoal
    AnnDPP0=mean(Netcashflow(i,2:end));
    CAnnnew=-Netcashflow(i,1)/((((1+financialGoals.interestRate)^TempPaybackGoal)-1)/((financialGoals.interestRate)*(1+financialGoals.interestRate)^TempPaybackGoal));
    SavingsDPP=CAnnnew-AnnDPP0;
    incentives_for_profit(i).additional_annual_savings_dpp = max(SavingsDPP, 0);
    
incentives_for_profit(i).IRRGoal = financialGoals.irr_goal; 
incentives_for_profit(i).DPPGoal =  financialGoals.paybackGoal;
end

end


