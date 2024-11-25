function [child] = ga_mutation(child, numCables, Pm)

Gene_no = length(child);

for k = 1:Gene_no
    R = rand();
    if R < Pm
        child(k) = randi([0 numCables]);
    end

end