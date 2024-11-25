function thermal = CHPthermal(Pelectric, type)
% [thermal] kwh of thermal generated when [Pelectric] kwh of electrical generated
if type == "NG"
    thermal = interp1([0, 100, 633, 1141, 3325, 9341, 9341000], ...
        [0, 178.7727, 832.3188, 1307.092, 3132.918, 7795.662, 7795662], Pelectric,'makima');
else
    
    %     thermal = interp1([0, 115, 170, 250, 360, 750, 7500], ...
    %         [0, 129, 183, 250, 371, 687, 6870], Pelectric,'makima');
    thermal = Pelectric .* 0.87772 + 35.2301;
    thermal(thermal <= 35.2301) = 0;
    
end