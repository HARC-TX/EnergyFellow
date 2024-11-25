function [child] = gaMutationDE(child, minBound, maxBound, nbus, dist, demand, nPipes, Pm)

%% mutation size
for k = 1:16
    R = rand();
    if R < Pm
        child(k) = randi([minBound(k), round(maxBound(k) *1.1)], 1);
    end
end
child(1:16) = gaPopSparse(child(1:16), minBound, maxBound);

%% mutation selectected building
R = rand();
if R < Pm
    selectBuilding = [1, randi(2, 1, nbus - 1)-1]; % make sure central plant is selected
    tempDemand = max(sum(demand(:, (selectBuilding(2:end))>0), 2));
    if sum(selectBuilding) > 2 && tempDemand > 1% at least 2 buildings are selected
            child(17:end) = tspSolver(find(selectBuilding), dist(:, 1:3)) * max(child(17:end));
    end
end
%% mutation pipe type
R = rand();
if R < Pm
        child(17:end) = child(17:end) / max(child(17:end)) * randi([1 nPipes]);
end