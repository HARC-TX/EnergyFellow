function []=log_function(msg,level)
arguments
    msg = 'opning text of log file.'
    level = "debug"
end

global log_level

if log_level == "error" && level == "debug"
    return
end

%check if there is a temporary folder to create log file
fid = fopen(fullfile(tempdir, 'amo-ce-log.txt'), 'a');
if fid == -1
    error('Cannot open log file.');
end
disp(msg)
fprintf(fid, 'time="%s" level="%s" msg="%s"\n', string(datetime('now', 'TimeZone','America/Chicago', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSxxx')), level, msg);
fclose(fid);

end