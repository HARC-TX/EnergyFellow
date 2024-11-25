function  [Sch, schBoiler, batt, tank, remainder, fminconMaxAttempts] = scheduler...
    (N, netP,thermal_load, batt, battMin, tank, tankMin, cost, fminconMaxAttempts)

sch = zeros(1,8);
schBoiler = 0;
remainder = 0;
demand = battMin + netP - batt;
if demand <= 0
    % power from PV is more than enough for resilience
    batt = min(batt - netP, N(10));
else
    % sch: NGCHP, H2CHP, BMCHP, NG, DG, H2G, BMG,Grid
    Pmin = N([3:9,12]) .* [0.25 0.25 0.25 0.25 0.25 0.25 0.25 0];
    % obtain max power for each tech
    Pavailable = N([3:9,12]);
    
    % kWh available from NGCHP
    if N(3) > 0 && CHPelectric(thermal_load + (N(11) - tank),"NG") > N(3) * 0.25
        Pavailable(1) = min(CHPelectric(thermal_load + (N(11) - tank),"NG"), N(3));
    else
        Pavailable(1) = 0;
        cost(1) = Inf;
    end
    % kWh available from H2CHP
    if N(4) > 0 && CHPelectric(thermal_load + (N(11) - tank),"H2") > N(4) * 0.25
        Pavailable(2) = min(CHPelectric(thermal_load + (N(11) - tank),"H2"), N(4));
    else
        Pavailable(2) = 0;
        cost(2) = Inf;
    end
    % kWh available from BMCHP
    if N(5) > 0 && CHPelectric(thermal_load + (N(11) - tank),"BM") > N(5) * 0.25
        Pavailable(3) = min(CHPelectric(thermal_load + (N(11) - tank),"BM"), N(5));
    else
        Pavailable(3) = 0;
        cost(3) = Inf;
    end
    
    % check if demand can be dispatched
    % check if gap between the grid and other tech exsits
    [gap, idx] = min(Pmin([1 1 1 1 1 1 1 0] & Pmin > 0));
    if ~isempty(gap) && gap > Pavailable(8) && gap > demand...
            && Pavailable(8) < demand && gap - demand <= N(10) - batt
        batt = batt + gap - demand;
        sch(idx) = gap;
    % check if demand exceeds tech capacity
    elseif demand >= sum(Pavailable)
        sch = Pavailable;
        remainder = demand - sum(Pavailable);
        if batt > 0
            batt = max(0, batt + sum(Pavailable) - netP);
        end
    else
        batt = battMin;
        % sort cost
        [~,index] = sort(cost);
        
        Pcumulate = cumsum(Pavailable(index));
        firstUndispatched = find(demand < Pcumulate,  1, 'first');
        lastDispatched = max(firstUndispatched - 1, 0);
        %disp(last_tech)
        sch(index) = (demand >= Pcumulate) .* Pavailable(index);
        remainder = Pavailable(index(firstUndispatched)) + demand - Pcumulate(firstUndispatched);
        while remainder > 0
            attemptDispatch = firstUndispatched;
            % starting from first undispatched tech, trying to dispatch the
            % remainder
            while attemptDispatch <= 8
                [schAttempt, remainderAttempt] = dispatchRemainder(remainder, Pmin, Pavailable, index, attemptDispatch);
                if remainderAttempt == 0
                    sch = sch + schAttempt;
                    remainder = 0;
                    break
                else
                    attemptDispatch = attemptDispatch + 1;
                end
            end
            % release the load which has been dispatched to the previous
            % tech to try on a more expensive tech
        if remainder > 0
            if lastDispatched < 1
                break
            end
            remainder = remainder + Pavailable(index(lastDispatched));
            sch(index(lastDispatched)) = 0;
            lastDispatched = lastDispatched - 1;
        end
        end
        % try fmincon if greedy failed
        if remainder > 0 && fminconMaxAttempts > 0
            try
                unitOpCost = [0;0;cost(1:7)';0;0;cost(8)];
                unitOpCost(unitOpCost == Inf) = 100;
                [fminconSch, ~, ~, ~, exitflag, attempts] = schedulerFmincon(N, demand,...
                    thermal_load, 0, 0, tank, tankMin, unitOpCost);
                fminconMaxAttempts = fminconMaxAttempts - attempts;
                if exitflag > 0
                    sch = fminconSch([1 2 3 4 5 6 7 10]);
                    %fprintf("fmincon exited with %i at netP = %f\n", exitflag, netP);
                end
            catch
            end
        end
    end
end

% Avoid double conversion in the case that thermal demand is dispached & tank is full to minimize error
if sum(sch(1:3)) > 0 && any(sch(1:3) == Pavailable(1:3) & sch(1:3) < N(3:5))
    tank = N(11);
else
    tank = tank + CHPthermal(sch(1),"NG")+ CHPthermal(sch(2),"H2") + CHPthermal(sch(3),"BM")- thermal_load; % PENDING
    if tank < tankMin
        schBoiler = tankMin - tank;
        tank = tankMin;
    end
end

Sch = [sch(1:7), 0, 0, sch(8)];
end

function [sch, remainder] = dispatchRemainder(remainder, Pmin, Pavailable, index, firstUndispatched)
sch = zeros(1,8);
for i = firstUndispatched : 8
            if remainder >= Pmin(index(i))
                if remainder <= Pavailable(index(i))
                    sch(index(i)) = remainder;
                    remainder = 0;
                    break
                elseif remainder > Pavailable(index(i))
                    sch(index(i)) = Pavailable(index(i));
                    remainder = remainder - Pavailable(index(i));
                end
            end
end
end