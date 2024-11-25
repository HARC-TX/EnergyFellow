function output = round_struct(input, N)
if isstruct(input)
    for i = 1:numel(input)
        fn = fieldnames(input);
        for j = 1:numel(fn)
            input(i).(fn{j}) = round_struct(input(i).(fn{j}), N);
        end
    end
    output = input;
elseif isnumeric(input)
    if abs(input) >= 1e6
        output = int64(input);
    else
        output = round(input, N);
    end
else
    output = input;
end
return
end

