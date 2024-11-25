function[V1, del1, PLoad, PLoss, Pij, Qij,  PLoss_ij,  QLoss_ij, lossCost, conv_flag] = pfa(Y, power_load, FT, hour_price, nbus)
global skipMode
power_load = [zeros(8760,1), power_load];
QL=atan(acos(.95)).*power_load;   % Maintain
nbus = size(Y,1);
SOL_P=zeros(8760,nbus);
SOL_Volt=zeros(8760,nbus);
SOL_Q=zeros(8760,nbus);

if strcmpi(skipMode, "true")
    computationLength = 60;
else
    computationLength = 8760;
end

%% NR ALGORITHM
for t = 1:computationLength
    pq = 2:nbus;
    npq = length(pq);
    BMVA = ceil(1.2 * max(power_load(t,:)));       % The factor 1.2 is chosen to scale correctly
    Pl = power_load(t,:)/BMVA;        % PLi..
    Ql = QL(t,:)/BMVA;        % QLi..
    Psp = -Pl;                    % P Specified..
    Qsp = -Ql;                    % Q Specified..
    G = real(Y);                % Conductance matrix..
    B = imag(Y);                % Susceptance matrix..

    % Initialization of state vector
    V = ones(nbus,1);
    del = zeros(nbus,1);
    T = [V, del];
    Tol = 1;
    Iter = 1;
    conv_flag = zeros(8760,1);

    while (Tol > 1e-4)   % Iteration starting..

        P = zeros(nbus,1);
        Q = zeros(nbus,1);
        % Calculate P and Q
        for i = 1:nbus
            for k = 1:nbus
                P(i) = P(i) + V(i)* V(k)*(G(i,k)*cos(del(i)-del(k)) + B(i,k)*sin(del(i)-del(k)));
                Q(i) = Q(i) + V(i)* V(k)*(G(i,k)*sin(del(i)-del(k)) - B(i,k)*cos(del(i)-del(k)));
            end
        end


        % Calculate change from specified value
        dPa = Psp'-P;
        dQa = Qsp'-Q;
        dQ = dQa;
        k = 1;
        dQ = zeros(npq,1);
        for i = 1:nbus
            dQ(k,1) = dQa(i);
            k = k+1;
        end
        dP = dPa(2:nbus);
        dQ = dQa(2:nbus);
        M = [dP ;dQ];       % Mismatch Vector

        % Jacobian
        % J1 - Derivative of Real Power Injections with Angles..
        J1 = zeros(nbus-1,nbus-1);
        for i = 1:(nbus-1)
            m = i+1;
            for k = 1:(nbus-1)
                n = k+1;
                if n == m
                    for n = 1:nbus
                        J1(i,k) = J1(i,k) + V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
                    end
                    J1(i,k) = J1(i,k) - V(m)^2*B(m,m);
                else
                    J1(i,k) = V(m)* V(n)*(G(m,n)*sin(del(m)-del(n)) - B(m,n)*cos(del(m)-del(n)));
                end
            end
        end

        % J2 - Derivative of Real Power Injections with V..
        J2 = zeros(nbus-1,npq);
        for i = 1:(nbus-1)
            m = i+1;
            for k = 1:npq
                n = pq(k);
                if n == m
                    for n = 1:nbus
                        J2(i,k) = J2(i,k) + V(n)*(G(m,n)*cos(del(m)-del(n)) + B(m,n)*sin(del(m)-del(n)));
                    end
                    J2(i,k) = J2(i,k) + V(m)*G(m,m);
                else
                    J2(i,k) = V(m)*(G(m,n)*cos(del(m)-del(n)) + B(m,n)*sin(del(m)-del(n)));
                end
            end
        end

        % J3 - Derivative of Reactive Power Injections with Angles..
        J3 = zeros(npq,nbus-1);
        for i = 1:npq
            m = pq(i);
            for k = 1:(nbus-1)
                n = k+1;
                if n == m
                    for n = 1:nbus
                        J3(i,k) = J3(i,k) + V(m)* V(n)*(G(m,n)*cos(del(m)-del(n)) + B(m,n)*sin(del(m)-del(n)));
                    end
                    J3(i,k) = J3(i,k) - V(m)^2*G(m,m);
                else
                    J3(i,k) = V(m)* V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
                end
            end
        end

        % J4 - Derivative of Reactive Power Injections with V..
        J4 = zeros(npq,npq);
        for i = 1:npq
            m = pq(i);
            for k = 1:npq
                n = pq(k);
                if n == m
                    for n = 1:nbus
                        J4(i,k) = J4(i,k) + V(n)*(G(m,n)*sin(del(m)-del(n)) - B(m,n)*cos(del(m)-del(n)));
                    end
                    J4(i,k) = J4(i,k) - V(m)*B(m,m);
                else
                    J4(i,k) = V(m)*(G(m,n)*sin(del(m)-del(n)) - B(m,n)*cos(del(m)-del(n)));
                end
            end
        end

        J = [J1 J2; J3 J4];     % Jacobian Matrix..
        %     if rcond(J)<1e-15
        %         break
        %     end
        %     X = inv(J)*M;           % Correction Vector
        X = J\M;                % Correction Vector
        %     X = inv(J) * M;
        dTh = X(1:nbus-1);      % Change in Voltage Angle..
        dV = X(nbus:end);       % Change in Voltage Magnitude..

        % Updating State Vectors..
        del(2:nbus) = dTh + del(2:nbus);    % Voltage Angle..
        V(2:nbus) = dV + V(2:nbus);    % Voltage Magnitude..
        T = [V, del];


        Iter = Iter + 1;
        Tol = max(abs(M));                  % Tolerance..
        if Iter > 20                        % Kill infinite loops
            conv_flag(t) = 1;
            break
        end

    end

    V1(t,:) = V';
    del1(t,:) = del';
    [Pij, Qij,  PLoss_ij(t,:),  QLoss_ij(t,:)] = powerFlow(V,del, Y, FT, BMVA);
    PLoad(t) = sum(power_load(t,:));
    PLoss(t) = sum(PLoss_ij(t,:));
    lossCost(t) = sum(PLoss_ij(t,:)) * hour_price;

end