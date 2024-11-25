function [child1, child2] = ga_crossover(parent1, parent2, Pc, crossoverName)

Gene_no = length(parent1);

switch crossoverName
    case 'single'
        
        Cross_p = randi(Gene_no-1);

        part1 = parent1(1:Cross_p);
        part2 = parent2(Cross_p+1:end);
        child1 = [part1, part2];

        part1 = parent2(1:Cross_p);
        part2 = parent1(Cross_p+1:end);
        child2 = [part1, part2];
        
    case 'double'
        
        cross_p1 = randi(Gene_no-1);
        cross_p2 = cross_p1;

        while cross_p2 == cross_p1
            cross_p2 = randi(Gene_no-1);
        end
        
        if cross_p1 > cross_p2
            temp = cross_p1;
            cross_p1 = cross_p2;
            cross_p2 = temp;
        end

        part1 = parent1(1:cross_p1);
        part2 = parent2(cross_p1 + 1:cross_p2);
        part3 = parent1(cross_p2 + 1:end);

        child1 = [part1, part2, part3];

        part1 = parent2(1:cross_p1);
        part2 = parent1(cross_p1 + 1:cross_p2);
        part3 = parent2(cross_p2 + 1:end);

        child2 = [part1, part2, part3];
        
end

R1 = rand();

if R1 > Pc
    child1 = parent1;
end

R2 = rand();

if R2 > Pc
    child2 = parent2;
end

end