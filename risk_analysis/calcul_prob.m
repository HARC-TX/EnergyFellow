function [prob_table]=calcul_prob(tech_data)

% the input is the probability distribution such as 'Triangle or Normal'and the value
%Prob_table is a Matrix 1000 *13 respectively the 13 elements are: 
%Ground_Based_PV %Rooftop_PV % NaturlGas% DieselGenerator% CombinedHeatPower% Battery% Tank% 
% UpGrid% cost_cap% cost_maint% cost_rep% cost_salvg% cost_misc

k=1;
distr=tech_data(:,2);
value=tech_data(:,3);
prob_table=zeros(1000,size(distr,1));
for i=1:size(distr,1)
    if strcmp(distr{i,1},'Normal')
        prob_table(:,k) = random('Normal',1,value{i,1},1000,1);
        k=k+1;
    elseif strcmp(distr{i,1},'Triangle')
        prob_table(:,k)= 1-value{i,1} + (value{i,1}+value{i,1})*rand(1000,1); %VARIATION triangular
        k=k+1;
    end
end