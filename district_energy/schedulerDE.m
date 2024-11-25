function  [Sch, tank, remainder, fminconMaxAttempts] = schedulerDE...
    (N, netP, tank, tankMin, cost, fminconMaxAttempts)

sch = zeros(1,8);
% schBoiler = 0;
% remainder = 0;
demand = tankMin + netP - tank;

    % cooling sch: NGHW, H2HW, BMHW, NG, H2, BM, EA, EW 
    % heating sch: NGCHP, H2CHP, BMCHP, NGB, H2B, BMB, EB, N/A
    Pmin = N(1:8) .* [0.25 0.25 0.25 0 0 0 0 0];
    % obtain max power for each tech
    Pavailable = N(1:8);
    
    if demand >= sum(Pavailable)
        sch = Pavailable;
        remainder = demand - sum(Pavailable);
        if tank > 0
            tank = max(0, tank + sum(Pavailable) - netP);
        end
    else
        tank = tankMin;
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

    end

Sch = sch;
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