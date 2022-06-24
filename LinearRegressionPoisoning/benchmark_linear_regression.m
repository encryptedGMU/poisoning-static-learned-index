% benmarking that invoke lr_poisoning. [distribution] specifies the kind
% of input used for synthesized data; [data_size_pool]

function [out_arr, out_arr_lad, out_arr_lad_max, out_arr_lad_var, time, timeavg] = ...
    benchmark_linear_regression(distribution, data_size_pool, ...
    density_pool, measure_time, run, percentage)

% dimensions
size_dimension = size(data_size_pool, 2);
density_dimension = size(data_size_pool, 2);

% output initialization
out_arr = zeros(run, percentage, size_dimension, density_dimension);
out_arr_lad = zeros(run, percentage, size_dimension, density_dimension);
out_arr_lad_max = zeros(run, percentage, size_dimension, density_dimension);
out_arr_lad_var = zeros(run, percentage, size_dimension, density_dimension);
time = zeros(size_dimension, density_dimension, run);

for ds = 1:size_dimension
    data_size = data_size_pool(ds);
    for dst = 1:density_dimension
        density = density_pool(dst);
        for run = 1:run
            if measure_time
                tic
                [out, out_lad, out_lad_max, out_lad_var] = ...
                    lr_Poisoning(distribution, data_size, density, percentage);
                time(ds, dst, run) = toc;
            else
                [out, out_lad, out_lad_max, out_lad_var] = ...
                    lr_Poisoning(distribution, data_size, density, percentage);
            end
            out_arr(run, :, ds, dst) = out;
            out_arr_lad(run, :, ds, dst) = out_lad;
            out_arr_lad_max(run, :, ds, dst) = out_lad_max;
            out_arr_lad_var(run, :, ds, dst) = out_lad_var;
        end
    end
end

if measure_time
    timeavg = sum(time, 3);
else
    timeavg = -1;
end

end