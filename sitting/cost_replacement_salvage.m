function [cfReplacement, salvageCost] = cost_replacement_salvage(LinesData, X, dist, power_load, life_project)   

cfReplacement = zeros(3, life_project+1);
salvageCost = [0; 0; 0];

%% power lines
cableType = X(X > 0);
cableLength = dist(X > 0);
for i = 1:length(LinesData.replacement)
    if LinesData.year_repl_pl(i) < life_project
        replaceYear = floor(LinesData.year_repl_pl(i):LinesData.year_repl_pl(i):life_project) + 1;
        cfReplacement(1, replaceYear(replaceYear <= life_project) + 1) = ...
            cfReplacement(1, replaceYear(replaceYear <= life_project) + 1) ...
            - LinesData.replacement(i) * sum(cableLength(cableType == i));
    end
    if rem(life_project, LinesData.year_repl_pl(i)) > 0
        salvageCost(1) = salvageCost(1) ...
            + (1 - rem(life_project / LinesData.year_repl_pl(i), 1)) ...
            * LinesData.replacement(i) * sum(cableLength(cableType == i));
    end
end

%% load center
xLC = [25, 50, 75, 100, 112.5, 150, 225, 300, 500, 750, 1000, 1500, 2500];
vLC = [5722, 6419, 8032, 6021, 8337, 34232, 49300, 37195, 45358, 52751, 77410, 105000, 159500] * 0.5;
if LinesData.year_repl_lc(1) < life_project
    replaceYear = floor(LinesData.year_repl_lc:LinesData.year_repl_lc:life_project) + 1;
    cfReplacement(2, replaceYear(replaceYear <= life_project) + 1) = ...
        -sum(interp1(xLC,vLC,max(power_load),'makima'));
end
if rem(life_project, LinesData.year_repl_lc(i)) > 0
    salvageCost(2) = (1 - rem(life_project / LinesData.year_repl_lc(i), 1)) ...
        * sum(interp1(xLC,vLC,max(power_load),'makima'));
end

%% substation
if LinesData.year_repl_subs(1) < life_project
    replaceYear = floor(LinesData.year_repl_subs:LinesData.year_repl_subs:life_project) + 1;
    cfReplacement(3, replaceYear(replaceYear <= life_project) + 1) = ...
        -LinesData.cost_repl_subs(1) * max(sum(power_load, 2));
end
if rem(life_project, LinesData.year_repl_subs(i)) > 0
    salvageCost(3) = (1 - rem(life_project / LinesData.year_repl_subs(i), 1)) ...
        * LinesData.cost_repl_subs(1) * max(sum(power_load, 2));
end

end