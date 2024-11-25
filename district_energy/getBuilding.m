function selectBuilding = getBuilding(connections, nbus)
if nbus == 0
    nbus = (sqrt(8*length(connections) + 1) + 1)/2;
end
temp = zeros(1,nbus^2); 
temp(find(tril(ones(nbus), -1))) = connections;
selectBuilding = find(any(reshape(temp,nbus,nbus),2)' | any(reshape(temp,nbus,nbus)));
selectBuilding = selectBuilding(2:end);