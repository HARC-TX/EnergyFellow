function value = isLegitConnection(V, nbus)
%% convert connections to matrix
M = zeros(nbus);
%get indices BELOW diagonale
indices = nonzeros(tril(reshape(1:nbus^2, nbus, nbus), -1));
M(indices(V > 0)) = 1;
M = M | M.';   %do the symmetry

%% check the topology
min_per_node= min(sum(M));
max_per_node= max(sum(M));
G = digraph(triu(M));
% number of island in the graph
weak_bins = conncomp(G,'Type','weak');

value = min_per_node >= 1 && max_per_node <= 3 ...
    && issymmetric(M) == 1 && max(weak_bins) == 1;