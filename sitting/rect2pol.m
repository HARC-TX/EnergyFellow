function [rho, theta] = rect2pol(x)
rho = abs(x);
theta = angle(x);
end