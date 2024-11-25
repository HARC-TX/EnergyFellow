function [v]= generateConnection(nbr_buildings,nbr_cables)
%nombre of buildings is n implies de nomber of link possibilies
%(n-1)!/2 if n=8 ==> 2520 possibilities
%number of ones on each side of the diagonale,
%this number varies between (n-1) 3*n,we can change the max by  (n-1)*n/2;
Msize = nbr_buildings;
%N=randi([(Msize-1) ((Msize-1)*Msize/2)],1);
if Msize>=3 &&  Msize<=5
    N=randi([(Msize-1) ((Msize-1)*Msize/2)],1);
else
    N=randi([(Msize*2) ((Msize-1)*Msize/2)],1);  
end
M = zeros(Msize);

%get indices BELOW diagonale
indices = nonzeros(tril(reshape(1:Msize^2, Msize, Msize), -1));
%pick N indices and fill with 1
M(indices(randperm(numel(indices), N))) = 1;
M = M | M.';   %do the symmetry
%check the feaseability of the generted matrix 
min_connection=2;
max_connection=3; 
for i=1:Msize 
     conections_per_node= sum(M(i,:));
     if (conections_per_node> max_connection)
        dif = conections_per_node- max_connection;
        %find the last surplus interconnections in the matrix
        position = find((M(i,:))==1,dif,'last');
        M(i,position)=0;
        M(position,i)=0;
     elseif (conections_per_node< min_connection)  
        position = find((M(i,:))==0,min_connection,'last');
        M(i,position) = 1;
        M(position,i) = 1;
     end
end
M = M - diag(diag(M));

%generate each connection node with specific cable section
Msection=randi(nbr_cables,1,Msize);
M2=M.*Msection;
idx = logical(triu(ones(size(M2)), 1));
v = M2(idx.'); 