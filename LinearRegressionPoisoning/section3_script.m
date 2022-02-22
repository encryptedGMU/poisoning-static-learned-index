% run this script to generate results from section 3.
% vary four different sizes
data_size_pool = [100, 500, 1000, 5000];
% vary four different densities
density_pool = [0.05, 0.1, 0.5, 0.8];
% change to false to disable time measurement
measure_time = true;
% measure 20 runs for each set of parameter.
run = 20;
% perform 15 percent of poisoning
percentage = 15;
% 0 for uniform distribution, 1 for normal distribution, 2 for log normal
% distribution.
distribution = 1;
% invoke [benchmark_linear_regression] and record results
[out_arr, out_arr_lad, out_arr_lad_max, out_arr_lad_var, time, timeavg] ...
    = benchmark_linear_regression(distribution, data_size_pool, ...
    density_pool, measure_time, run, percentage);

% plotting function specialized for formatting the figure appeared in
% the paper.
make_plots();