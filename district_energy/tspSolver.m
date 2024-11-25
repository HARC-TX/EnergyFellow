function [gene] = tspSolver(selectedBuilding, dist)
filterDist = [];
for i = 1:size(selectedBuilding,2)
    filterDist = [filterDist; [ones(size(selectedBuilding,2) - i, 1) .* selectedBuilding(i), selectedBuilding((i+1):end)']];
end

for i = 1:size(filterDist, 1)
    filterDist(i, 3) = dist((dist(:,1) == filterDist(i,1)) & (dist(:,2) == filterDist(i,2)), 3);
end

G = graph(filterDist(:,1),filterDist(:,2));

tsp = optimproblem;
trips = optimvar('trips',size(filterDist,1),1,'Type','integer','LowerBound',0,'UpperBound',1);
tsp.Objective = filterDist(:,3)'*trips;
constr2trips = optimconstr(size(selectedBuilding,2),1);
for stop = 1:size(selectedBuilding,2)
    whichIdxs = outedges(G,selectedBuilding(stop)); % Identify trips associated with the stop
    constr2trips(selectedBuilding(stop)) = sum(trips(whichIdxs)) == 2;
end
tsp.Constraints.constr2trips = constr2trips;
opts = optimoptions('intlinprog','Display','off');
tspsol = solve(tsp,'options',opts);
tspsol.trips = logical(round(tspsol.trips));
Gsol = graph(filterDist(tspsol.trips,1),filterDist(tspsol.trips,2),[],numnodes(G));

tourIdxs = conncomp(Gsol);
numtours = max(tourIdxs(selectedBuilding)); % Number of subtours
k = 1;
while numtours > 1 % Repeat until there is just one subtour
    % Add the subtour constraints
    for ii = 1:numtours
        inSubTour = (tourIdxs == ii); % Edges in current subtour
        a = all(inSubTour(filterDist(:,1:2)),2); % Complete graph indices with both ends in subtour
        constrname = "subtourconstr" + num2str(k);
        tsp.Constraints.(constrname) = sum(trips(a)) <= (nnz(inSubTour) - 1);
        k = k + 1;        
    end
    
    % Try to optimize again
    [tspsol,fval,exitflag,output] = solve(tsp,'options',opts);
    tspsol.trips = logical(round(tspsol.trips));
    Gsol = graph(filterDist(tspsol.trips,1),filterDist(tspsol.trips,2),[],numnodes(G));
    
    tourIdxs = conncomp(Gsol);
    numtours = max(tourIdxs(selectedBuilding)); % Number of subtours
end

gene = zeros(1,size(dist,1));

for i = 1:size(Gsol.Edges, 1)
    gene((dist(:,1) == Gsol.Edges{i,:}(1)) & (dist(:,2) == Gsol.Edges{i,:}(2))) = 1;
end
