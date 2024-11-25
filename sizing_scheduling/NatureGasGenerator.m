function [unitCost, standbyCost] = NatureGasGenerator(capacity)
% [unitCost] kwh of nature gas per kwh generated and [standbyCost] kwh of
% nature gas per hour for a [capacity] kw generator

x = [20, 30, 40, 60, 75, 100, 125, 135, 150, 175, 200, 230, 250, 300, ...
    350, 400, 500, 600, 750, 1000, 1000000];
% dummy data at 1e6 to avoid incorrect trend
v = [0.25768288, 0.275616853, 0.285150176, 0.295438613, 0.299780523, ...
    0.303442829, 0.305640212, 0.306240948, 0.307407181, 0.308410405, ...
    0.309162822, 0.309958155, 0.310397435, 0.311069487, 0.311678972, ...
    0.31210777, 0.312662779, 0.313051663, 0.313448098, 0.313852084,0.314];

unitCost = interp1(x,v,capacity,'makima') ./ 25.74255 .* 293.07107; % 25.74255 m3 of NG per MMBTU, 293.07107 kwh per MMBTU
standbyCost = (0.0477 * capacity + 2.0711) ./ 25.74255 .* 293.07107;