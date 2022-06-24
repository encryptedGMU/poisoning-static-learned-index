% Script that runs RMIPoisoning reapeatedly and generates expreiment data
% on synthesized data.

store = cell(3, 3, 3, 2);
original_data = cell(2, 1);
poisoned_data = cell(3, 3, 3, 2);
original_mses_pool = cell(3, 3, 3, 2);
intermediate_mses_pool = cell(3, 3, 3, 2);
num_iter = zeros(3, 3, 3, 2);
times = zeros(3, 3, 3, 2);

original_lad_pool = cell(3, 3, 3, 2);
original_lad_max_pool = cell(3, 3, 3, 2);
original_lad_var_pool = cell(3, 3, 3, 2);
Loss_lad_pool = cell(3, 3, 3, 2);
Loss_lad_max_pool = cell(3, 3, 3, 2);
Loss_lad_var_pool = cell(3, 3, 3, 2);


data_size = 10000000;
bucket_size_pool = [100, 1000, 10000]; % horizontal aligned
num_buckets_pool = [ceil(data_size/100), ceil(data_size/1000), ceil(data_size/10000)]; % vertical aligned
density_pool = [0.01, 0.2]; % different shade
poison_percentage_pool = [0.05, 0.1, 0.2]; % x axis
ratio_amp_pool = [2, 3]; % different scatter points
% params
threshold = 1;
min_poison_num = 0;


for kk = 1:2 
    density = density_pool(kk);
    sample_range = data_size/density;
    %kk=1;
    raw_dataset = sort(randsample(sample_range, data_size));
    %raw_dataset = sort(samplenormal(sample_range, data_size));
    original_data(kk) = {raw_dataset};
    %raw_dataset;
    for ii = 1:3
        num_buckets_raw = num_buckets_pool(ii);
        bucket_size = bucket_size_pool(ii);
        for ll = 1:3
            poison_percentage = poison_percentage_pool(ll);
            num_buckets = ceil(num_buckets_raw*(1+poison_percentage));
            init_b_size = floor(data_size/num_buckets);
            dataset = raw_dataset(1:int32(init_b_size*num_buckets));
            for mm = 2:2
                ratio_amp = ratio_amp_pool(mm);
                ratio = 1-poison_percentage*ratio_amp;

                start_time = cputime;
                % 2 for normal distribution
                RMIPoisoning(sample_range, num_buckets, bucket_size, ratio, threshold)

                times(ii, kk, ll, mm) = cputime-start_time;
                num_iter(ii, kk, ll, mm) = counter;
                store(ii, kk, ll, mm) = {Loss_arr};
                poisoned_data(ii, kk, ll, mm) = {poisoned_dataset};
                intermediate_mses_pool(ii, kk, ll, mm) = {intermediate_mses};
                original_mses_pool(ii, kk, ll, mm) = {original_mses};
                
                original_lad_pool(ii, kk, ll, mm) = {original_lad};
                original_lad_max_pool(ii, kk, ll, mm) = {original_lad_max};
                original_lad_var_pool(ii, kk, ll, mm) = {original_lad_var};
                
                Loss_lad_pool(ii, kk, ll, mm) = {Loss_lad};
                Loss_lad_max_pool(ii, kk, ll, mm) = {Loss_lad_max};
                Loss_lad_var_pool(ii, kk, ll, mm) = {Loss_lad_var};
            end
        end
    end
end