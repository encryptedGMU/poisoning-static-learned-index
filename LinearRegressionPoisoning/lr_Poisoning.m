% The function takes an distribution and dataset size (after poisoning),
% along with the density of the dataset defined by [data_size/range].
% It inserts 15 percent of poisoning datapoints and record the effect 
% of MSE and LAD error for each percent inserted. 
% The results are recorded into output arrays.
function [out, out_lad, out_lad_max, out_lad_var] = ...
    lr_Poisoning(distribution, data_size, density, percentage)

% metadata
% the range of dataset
sample_range = data_size/density;
% the size of dataset before poisoning.
original_size = (100-percentage)/100*data_size;

% sample data
if distribution == 0 
    % uniform
    dataset = sort(randsample(sample_range, original_size))';
elseif distribution == 1
    % normal
    dataset = samplenormal(sample_range, original_size);
elseif distribution == 2
    %lognormal
    dataset = sampleln(sample_range, original_size);
else
    error("Undefined distribution code!");
end


% output parameters
% The array of MSE recorded for each percent of poisoning
out = zeros(1, 15);
% The array of LAD recorded for each percent of poisoning
out_lad = zeros(1, 15);
% The array of maximum LAD error recorded for each percent of poisoning
out_lad_max = zeros(1, 15);
% The array of variance of LAD recorded for each percent of poisoning
out_lad_var = zeros(1, 15);

% main algorithm
% initialize parameters
K = dataset;
R = 1:size(K, 2);
Ek = mean(K);
Ek2 = mean(K.*K);
Er = mean(R);
Er2 = mean(R.*R);
Ekr = mean(K.*R);
Vk = Ek2-Ek*Ek;
Vr = Er2-Er*Er;
Ckr = Ekr-Ek*Er;
w = Ckr/Vk;
b = Er-w*Ek;
% mse errors
original_mse = Vr-Ckr*Ckr/Vk;
loss = original_mse;
% lad errors
original_lad = 0;
original_lad_max = 0;
original_lad_var = 0;
for idx = R
    original_lad = original_lad + abs(w*K(idx)+b-idx);
    original_lad_max = max(original_lad_max, abs(w*K(idx)+b-idx));
end
original_lad = original_lad/R(end);

for idx = R
    original_lad_var = original_lad_var + (abs(w*K(idx)+b-idx)-original_lad)^2;
end


% init poisoning parameters
lo = dataset(1);
hi = sample_range;


kp = lo;
rp = 1;
K0 = K;
K = [kp, K0];
n = original_size+1;
R = 1:n;

for l1 = 0:14
    for l2 =1:1
        % compute parameters
        Ek = mean(K);
        Ek2 = mean(K.*K);
        Er = mean(R);
        Er2 = mean(R.*R);
        Ekr = mean(K.*R);
        Vk = Ek2-Ek*Ek;
        Vr = Er2-Er*Er;
        Ckr = Ekr-Ek*Er;
        w = Ckr/Vk;
        b = Er-w*Ek;
        L = Vr-Ckr*Ckr/Vk;
        maxL = L;
        maxkp = kp;
        % gradient parameters
        for j = 1:n-1
            dkp = K(j+1)-K(j);
            % compute gradients
            dEk = dkp/n;
            dEk2 = (2*kp+dkp)*dkp/n;
            dEr = 0;
            dEr2 = 0;
            dEkr = rp*dkp/n;
            dVk = dEk2 - 2*Ek*dEk - dEk*dEk;
            dVr = dEr2 - 2*Er*dEr - dEr*dEr;
            dCkr = dEkr - Er*dEk - dEr*Ek - dEr*dEk;
            L = -(Ckr+dCkr)^2/(Vk+dVk)+(Vr+dVr);
            % update params
            Ek = Ek+dEk;
            Ek2 = Ek2+dEk2;
            Er = Er+dEr;
            Er2 = Er2+dEr2;
            Ekr = Ekr+dEkr;
            Vk = Vk+dVk;
            Vr = Vr+dVr;
            Ckr = Ckr+dCkr;
            % update position
            rp = rp+1;
            kp = K(j+1);
            if L > maxL
                maxL = L;
                maxkp = kp;
            end
        end
        % update kp
        kp = maxkp;

        % find near empty slot
        diff = hi;
        pos = lo;
        slots = setdiff(lo:hi, K);
        for bad = slots
            if diff > abs(kp-bad)
                diff = abs(kp-bad);
                pos = bad;
            end
        end
        
        K = sort([K0, pos]);
        R = 1:n;
        Ek = mean(K);
        Ek2 = mean(K.*K);
        Er = mean(R);
        Er2 = mean(R.*R);
        Ekr = mean(K.*R);
        Vk = Ek2-Ek*Ek;
        Vr = Er2-Er*Er;
        Ckr = Ekr-Ek*Er;
        loss = Vr-Ckr*Ckr/Vk;
        % update for next itr
        kp = lo;
        rp = 1;
        K0 = K;
        K = [kp, K0];
        n = n+1;
        R = 1:n;
    end
    % out1
    out(l1+1) = loss/original_mse;
    % out2
    for idx = R
        out_lad(l1+1) = out_lad(l1+1) + abs(w*K(idx)+b-idx);
        out_lad_max(l1+1) = max(out_lad_max(l1+1), abs(w*K(idx)+b-idx));
    end
    out_lad(l1+1) = out_lad(l1+1)/R(end);
    
    for idx = R
        out_lad_var(l1+1) = out_lad_var(l1+1) + (abs(w*K(idx)+b-idx)-out_lad(l1+1))^2;
    end
    out_lad_var(l1+1) = out_lad_var(l1+1)/R(end);
end

end
