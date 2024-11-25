
function [pv_out] = funcPV(G, T_amb, T_cell,PV_rated,Temp_coeff,eff_pv)

pv_out = ((PV_rated * (G/1000) * (1 + Temp_coeff*(T_amb + 0.0256*G - T_cell)))/1000)* eff_pv; 

end