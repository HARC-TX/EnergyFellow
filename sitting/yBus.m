
function [ybus, SR] = yBus(X, Dist, nbus,lines_data)
              
idx = Dist(:,2) > 0;
Dist = [Dist(idx,1) Dist(idx,2) Dist(idx,3)];
y = lines_Param(X, Dist,lines_data);
SR = Dist(:,1:2);
fb = SR(:,1);
tb = SR(:,2);



nbranch = length(fb);           % no. of branches...
ybus = zeros(nbus,nbus);        % Initialise YBus...
 
 % Formation of the Off Diagonal Elements...
 for k=1:nbranch
     ybus(fb(k),tb(k)) = ybus(fb(k),tb(k))-y(k);
     ybus(tb(k),fb(k)) = ybus(fb(k),tb(k));
 end
 
 % Formation of Diagonal Elements....
 for m =1:nbus
     for n =1:nbranch
         if fb(n) == m
             ybus(m,m) = ybus(m,m) + y(n);
         elseif tb(n) == m
             ybus(m,m) = ybus(m,m) + y(n);
         end
     end
 end


end