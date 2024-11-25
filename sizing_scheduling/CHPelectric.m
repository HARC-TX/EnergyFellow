function Pelectric = CHPelectric(thermal, type)
% [Pelectric] kwh of electrical generated when [thermal] kwh of thermal generated
if type == "NG"
    Pelectric = interp1([0, 178.7727, 832.3188, 1307.092, 3132.918, 7795.662, 7795662], ...
        [0, 100, 633, 1141, 3325, 9341, 9341000], thermal,'makima');
else
    %     Pelectric = interp1([0, 129, 183, 250, 371, 687, 6870], ...
    %         [0, 115, 170, 250, 360, 750, 7500], thermal,'makima');
    Pelectric = thermal ./ 0.87772 - 40.1382;
    Pelectric(Pelectric <= 0) = 0;
end