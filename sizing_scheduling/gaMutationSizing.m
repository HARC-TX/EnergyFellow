function [child] = gaMutationSizing(child, Pm, Problem)

Gene_no = length(child);

for k = 1:Gene_no
    R = rand();
    if R < Pm
        child(k) = randi([Problem.lb(k), round(Problem.ub(k) *1.1)], 1);
    end
end

child = gaPopSparse(child, Problem.lb, Problem.ub);

if child(Gene_no) > 0
    child(Gene_no) = Problem.ub(Gene_no);
end