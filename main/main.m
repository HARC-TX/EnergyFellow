function[]=main(task_id, args)
arguments
    task_id = ''
    args.devMode = 'local'
    args.logLevel = 'error'
    args.skipMode = 'false'
    args.host = 'amo-com'
    args.port = '8888'
    args.parallel = 'false'
    args.ga = ""
end

import matlab.net.*
import matlab.net.http.*
import matlab.net.http.field.*

global web_host
global log_level
global skipMode
global parallel

% diary
tic
engineVersion = [2, 4, 7];
task_id = convertStringsToChars(task_id);
if strlength(task_id) ~= 36
    disp("incorrect task_id length")
    fprintf("task_id: %s\n", task_id);
    disp(task_id)
    log_level = 'error';
    log_function(sprintf("Incorrect task_id length: %s", task_id), 'error');
    quit(249);
end

log_level = lower(args.logLevel);

log_function(sprintf("Computation Engine Version %i.%i.%i", engineVersion), 'info');

skipMode = lower(args.skipMode);

if strcmpi(args.parallel, "false")
    parallel = 1;
else
    if strcmpi(args.parallel, "true")
        parallel = 2;
        log_function("parallel with default threads", 'info');
    else
        parallel = str2double(args.parallel);
        delete(gcp('nocreate'))
        parpool(parallel);
        log_function(sprintf("parallel with %i workers", parallel), 'info');
    end
end 
rng('shuffle')
currentStepTime = toc;
lastStepTime = currentStepTime;
log_function(sprintf("Initalized in %f seconds", currentStepTime), 'info');

format short;

currentFolder=pwd;
slach='/';

%% fetch json file
    jsonText = fileread(strcat(currentFolder,slach,'userInput',slach,task_id,'.json'));
    inputJSON = jsondecode(jsonText);
    log_function("Json file is fetched locally");

currentStepTime = toc-lastStepTime;
lastStepTime = lastStepTime + currentStepTime;
log_function(sprintf("Json fetched in %f seconds", currentStepTime), 'info');

%% create results folder in the current folder
result_folder= strcat( currentFolder,slach,'results_output',slach);
if ~exist(result_folder,'dir')
    mkdir(result_folder)
    log_function("result folder made");
end

%% read json
[nbus,dist,power_load,thermal_load,cooling_load,lines_data,...
    tech_data,weather_data,data_genetic, pipeData, state_tech, techNames, financialGoals,...
    SolarMatrix, solarProdMatrix]=read_json(inputJSON);

%% read GA startup parameters
if strlength(args.ga) > 30
    try tmp_genertic = str2num(args.ga);
        if all(size(tmp_genertic) == [5, 3], 'all') ...
                && all([round(tmp_genertic(1:2, :)) > 1; tmp_genertic(3:5, :) < 1], 'all')
            data_genetic = [round(tmp_genertic(1:2, :)); tmp_genertic(3:5, :)];
            log_function(sprintf("Genertic parameter is [%s]",...
                extractAfter(strrep(num2str(reshape(data_genetic',1,[]),',%.3g'),' ',''), ',')));
        else
            log_function('Incorrect genertic parameters', "error");
        end
    catch
        log_function('Unable to phrase genertic parameters', "error");
    end
end

currentStepTime = toc-lastStepTime;
lastStepTime = lastStepTime + currentStepTime;
log_function(sprintf("Json phrased in %f seconds", currentStepTime), 'info');

if financialGoals.systemType == "Micro Grid"
%% call sitting function
    
    [sitting_result, sol_pop,best_sol, cgcurve, sitingUniqueGene] = siting...
        (nbus,dist{:, 1:4},power_load,financialGoals, lines_data,data_genetic);
    currentStepTime = toc-lastStepTime;
    lastStepTime = lastStepTime + currentStepTime;
    log_function(sprintf("Micro Grid Sitting finished in %f seconds", currentStepTime), 'info');
    % save sitting data in a json file
    s1 = strcat(result_folder,'sitting_result.json');
    fid1=fopen(s1, 'w');
    sit_data= jsonencode(sitting_result);
    
    fwrite(fid1, sit_data);
    fclose(fid1);

%% call sizing function
[sizing_result, sizingUniqueGene] = sizing_scheduling(financialGoals,power_load,thermal_load,weather_data,...
    tech_data, data_genetic,state_tech,SolarMatrix,solarProdMatrix);

currentStepTime = toc-lastStepTime;
lastStepTime = lastStepTime + currentStepTime;
log_function(sprintf("Micro Grid Sizing finished in %f seconds", currentStepTime), 'info');
%%%save sizing data
s2 = strcat(result_folder,'sizing_result.json');
fid2=fopen(s2, 'w');
siz_data= jsonencode(sizing_result);
fwrite(fid2, siz_data);
fclose(fid2);

else
    [sitting_result, sizing_result, sizingUniqueGene] ...
        = districtEnergy(nbus,dist{:, 1:4},thermal_load, cooling_load,weather_data,pipeData,state_tech,data_genetic,financialGoals);
    sitingUniqueGene = 0;
end
%% call risk analysis function
    [output_results] = risk_analysis(sitting_result,sizing_result,dist,...
        lines_data,tech_data,techNames,financialGoals, sitingUniqueGene, sizingUniqueGene);
    
    currentStepTime = toc-lastStepTime;
    lastStepTime = lastStepTime + currentStepTime;
    log_function(sprintf("Risk analysis finished in %f seconds", currentStepTime), 'info');
    %%%%%%% save risk analysis data
    save (strcat(currentFolder,'\results_output\output_results.mat'),'output_results');

%% Generate output json
output_Data.taskId = task_id;
output_Data.finished = string(datetime('now', 'TimeZone','America/Chicago',...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSxxx'));
output_Data.version = engineVersion;

if size(output_results, 2) > 5
    output_Data.summaryData = gen_output(output_results(1), financialGoals, state_tech);
    output_Data.customizedSolution = gen_output(output_results(end), financialGoals, state_tech);
    output_Data.customizedSolution.analyzedSolution = 1;
else
    output_Data.summaryData = gen_output(output_results(1), financialGoals, state_tech);
    output_Data.customizedSolution = string(nan);
end

%% Write final json output to file
jsonText = jsonencode(output_Data, "PrettyPrint" , true);
fid = fopen(strcat(currentFolder,'/results_output/new_output.json'), 'w');
fprintf(fid, '%s', jsonText);
fclose(fid);


currentStepTime = toc;
log_function(sprintf("Computation finished in %f seconds", currentStepTime), 'info');
