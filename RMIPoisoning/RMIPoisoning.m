% inputs:   sample_range is the possible key set
%           num_buckets is the number of second stage models
%           bucket_size is the second stage model size
%           ratio is the maximum percentage of points that can be inserted
%               in each second stage model
%           threshold is the minimum MSE increment in the second stage
%               model. Algorithm is converged if increment is below
%               threshold.
%           output variables are evident in their variable names.
function [Loss_arr, poisoned_dataset, original_mses, ... 
    original_lad, original_lad_max, original_lad_var, ...
    Loss_lad, Loss_lad_max, Loss_lad_var] = ...
    RMIPoisoning(distribution, sample_range, num_buckets, bucket_size, ratio, threshold)
    
    % derivative metadata
    low_bound = bucket_size*ratio;
    min_poison_num = 0;
    max_poison_num = ceil(bucket_size - low_bound);
    original_num = init_b_size*ones(1, num_buckets);
    poison_num = bucket_size*ones(1, num_buckets)-original_num;
    
    % generate synced dataset
    data_size = init_b_size * num_buckets;
    if (distribution == 1)
        dataset = sort(randsample(sample_range, data_size));
    elseif (distribution == 2)
        dataset = samplenormal(sample_range, original_size);
    elseif (distribution == 3)
        dataset = sampleln(sample_range, original_size);
    else
        error("Undefined distribution code!");
    end
    divided_dataset = reshape(dataset, [init_b_size, num_buckets])';
    poison_keys = ones(num_buckets, max_poison_num)*(-1);
    
    % initial specs
    original_mses = zeros(1, num_buckets);
    original_lad = zeros(1, num_buckets);
    original_lad_max = zeros(1, num_buckets);
    original_lad_var = zeros(1, num_buckets);
    
    for i = 1:num_buckets
        K = divided_dataset(i, :);
        if ~issorted(K)
            error("not sorted!");
        end
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
        % mse
        original_mses(i) = Vr-Ckr*Ckr/Vk;
        % lad
        for idx = R
            original_lad(i) = original_lad(i) + abs(w*K(idx)+b-idx);
            original_lad_max(i) = max(original_lad_max(i), abs(w*K(idx)+b-idx));
        end
        original_lad(i) = original_lad(i)/R(end);
    
        for idx = R
            original_lad_var(i) = original_lad_var(i) + (abs(w*K(idx)+b-idx)-original_lad(i))^2;
        end
        original_lad_var(i) = original_lad_var(i)/R(end);
        
    end
    
    poisoned_dataset = zeros(num_buckets, bucket_size);
    % init poisoning
    lo = divided_dataset(1, 1)-1;
    for i = 1:num_buckets        
        % insert first poisoning data
        kp = lo;
        rp = 1;
        K0 = divided_dataset(i, :);
        K = [kp, K0];
        n = init_b_size+1;
        R = 1:n;
        %K0
        for l =(1:bucket_size-n+1)
            % compute parameters
            Ek = mean(K);
            Ek2 = mean(K.*K);
            Er = mean(R);
            Er2 = mean(R.*R);
            Ekr = mean(K.*R);
            Vk = Ek2-Ek*Ek;
            Vr = Er2-Er*Er;
            Ckr = Ekr-Ek*Er;
            L = Vr-Ckr*Ckr/Vk;
            maxL = L;
            maxkp = kp;
            maxrp = rp;
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
                    maxrp = rp;
                end
            end
            % update kp
            kp = maxkp;
            rp = maxrp-1;
        
            % find near empty slot
            j = 0;
            while rp-j>0 && rp+j+2<=n-1 && K(rp-j) == kp-j-1 && K(rp+j+2)== kp+j+1
                j = j+1;
            end
            loss = 0;
            if rp-j-1<=0
                K = [kp-j-1, K0];
                poison_keys(i, l) = kp-j-1;
                % compute MSE
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
            elseif rp-j-1>=n
                
            elseif K0(rp-j-1) ~= kp-j-1
                K = [K0(1:rp-j-1), kp-j-1, K0(rp-j:end)];
                poison_keys(i, l) = kp-j-1;
                % compute MSE
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
            end
            
            if rp+j+1>=n
                Ktmp = [K0, kp+j+1];
                % compute MSE
                R = 1:n;
                Ek = mean(Ktmp);
                Ek2 = mean(Ktmp.*Ktmp);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(Ktmp.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                if Vr-Ckr*Ckr/Vk > loss
                    K = [K0, kp+j+1];
                    poison_keys(i, l) = kp+j+1;
                end
            elseif K0(rp+j+1) ~= kp+j+1
                Ktmp = [K0(1:rp+j), kp+j+1, K0(rp+j+1:end)];
                % compute MSE
                R = 1:n;
                Ek = mean(Ktmp);
                Ek2 = mean(Ktmp.*Ktmp);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(Ktmp.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                if Vr-Ckr*Ckr/Vk > loss
                    K = [K0(1:rp+j), kp+j+1, K0(rp+j+1:end)];
                    poison_keys(i, l) = kp+j+1;
                end
            end
            % update for next itr
            kp = lo;
            rp = 1;
            K0 = K;
            K = [kp, K0];
            n = n+1;
            R = 1:n;
        end
        
        % update lo and hi
        lo = max(K(n)+1, kp);
        poisoned_dataset(i, :) = K0;
        
    end
    
    % parameters
    Ek_arr = mean(poisoned_dataset, 2);
    Ek2_arr = mean(poisoned_dataset.*poisoned_dataset, 2);
    Er_arr = ones(num_buckets, 1)*mean(1:bucket_size);
    Er2_arr = ones(num_buckets, 1)*mean((1:bucket_size).^2);
    Ekr_arr = (poisoned_dataset*(1:bucket_size)'/bucket_size);
    Vk_arr = (Ek2_arr)-(Ek_arr.*Ek_arr);
    Vr_arr = (Er2_arr)-(Er_arr.*Er_arr);
    Ckr_arr = (Ekr_arr)-(Ek_arr.*Er_arr);
    Loss_arr = Vr_arr-(Ckr_arr.*Ckr_arr)./(Vk_arr); 
    
    % compute gradients
    dLosses = zeros(num_buckets, 4);
    k_in = zeros(num_buckets, 4);
    r_in = zeros(num_buckets, 4);
    k_out = zeros(num_buckets, 4);
    r_out = zeros(num_buckets, 4);
    n=bucket_size;
    for i = 1:num_buckets
        if i < num_buckets
            % k_p to next segment
            k_in(i, 1) = poisoned_dataset(i+1, 1);
            r_in(i, 1) = bucket_size;
            k_out(i, 1) = poison_keys(i, poison_num(i));
            [~, r_out(i, 1)] = min(abs(poisoned_dataset(i, :)-k_out(i, 1)));
            K = [poisoned_dataset(i, 1:(r_out(i, 1)-1)), poisoned_dataset(i, (r_out(i, 1)+1):end), k_in(i, 1)];
            R = 1:bucket_size;
            % update loss
            Ek = mean(K);
            Ek2 = mean(K.*K);
            Er = mean(R);
            Er2 = mean(R.*R);
            Ekr = mean(K.*R);
            Vk = (Ek2)-(Ek*Ek);
            Vr = (Er2)-(Er*Er);
            Ckr = (Ekr)-(Ek*Er);
            L = Vr-(Ckr*Ckr)/(Vk);
            dLosses(i, 1) = L-Loss_arr(i);
    
            % k_p from next segment
            % find k_in as a new poison point
            k_in(i, 2) = 0;
            r_in(i, 2) = 0;
            k_out(i, 2) = poisoned_dataset(i, bucket_size);
            r_out(i, 2) = bucket_size;
            K0 = poisoned_dataset(i, 1:(end-1));
            R = 1:bucket_size;
    
            % find near empty slot
            kp = poison_keys(i, poison_num(i));
            [~, rp] = min(abs(K0-kp));
            j = 0;
            while rp-j-1>0 && rp+j+1<n && K0(rp-j-1) == kp-j-1 && K0(rp+j+1)== kp+j+1
                j = j+1;
            end
            loss = 0;
            if rp-j-1<=0
                K = [kp-j-1, K0];
                k_in(i, 2) = kp-j-1;
                r_in(i, 2) = 1;
                % compute MSE
                Ek = mean(K);
                Ek2 = mean(K.*K);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(K.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                loss = Vr-Ckr*Ckr/Vk;
            elseif K0(rp-j-1) ~= kp-j-1
                K = [K0(1:rp-j-1), kp-j-1, K0(rp-j:end)];
                k_in(i, 2) = kp-j-1;
                r_in(i, 2) = rp-j-1;
                % compute MSE
                Ek = mean(K);
                Ek2 = mean(K.*K);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(K.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                loss = Vr-Ckr*Ckr/Vk;
            end
    
            if rp+j+1>=n
                Ktmp = [K0, kp+j+1];
                % compute MSE
                Ek = mean(Ktmp);
                Ek2 = mean(Ktmp.*Ktmp);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(Ktmp.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                if Vr-Ckr*Ckr/Vk > loss
                    k_in(i, 2) = kp+j+1;
            	    r_in(i, 2) = bucket_size;
                    loss = Vr-Ckr*Ckr/Vk;
                end
            elseif K0(rp+j+1) ~= kp+j+1
                Ktmp = [K0(1:rp+j), kp+j+1, K0(rp+j+1:end)];
                % compute MSE
                Ek = mean(Ktmp);
                Ek2 = mean(Ktmp.*Ktmp);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(Ktmp.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                if Vr-Ckr*Ckr/Vk > loss
                    k_in(i, 2) = kp+j+1;
                    r_in(i, 2) = rp+j+1;
                    loss = Vr-Ckr*Ckr/Vk;
                end
            end
            dLosses(i, 2) = loss-Loss_arr(i);
        end
        
        if i > 1
            % k_p to prev segment
            k_in(i, 3) = poisoned_dataset(i-1, bucket_size);
            r_in(i, 3) = 1;
            k_out(i, 3) = poison_keys(i, poison_num(i));
            [~, r_out(i, 3)] = min(abs(poisoned_dataset(i, :)-k_out(i, 3)));
            K = [k_in(i, 3), poisoned_dataset(i, 1:(r_out(i, 3)-1)), poisoned_dataset(i, (r_out(i, 3)+1):end)];
            R = 1:bucket_size;
            % update loss
            Ek = mean(K);
            Ek2 = mean(K.*K);
            Er = mean(R);
            Er2 = mean(R.*R);
            Ekr = mean(K.*R);
            Vk = (Ek2)-(Ek*Ek);
            Vr = (Er2)-(Er*Er);
            Ckr = (Ekr)-(Ek*Er);
            L = Vr-(Ckr*Ckr)/(Vk);
            dLosses(i, 3) = L-Loss_arr(i);
    
            
            % k_p from prev segment
            k_in(i, 4) = 0;
            r_in(i, 4) = 0;
            k_out(i, 4) = poisoned_dataset(i, 1);
            r_out(i, 4) = 1;
            K0 = poisoned_dataset(i, 2:end);
            R = 1:bucket_size;
            
            % find near empty slot
            kp = poison_keys(i, poison_num(i));
            [~, rp] = min(abs(K0-kp));
            j = 0;
            while rp-j-1>0 && rp+j+1<=n-1 && K0(rp-j-1) == kp-j-1 && K0(rp+j+1)== kp+j+1
                j = j+1;
            end
            loss = 0;
            if rp-j-1<=0
                K = [kp-j-1, K0];
                k_in(i, 4) = kp-j-1;
                r_in(i, 4) = 1;
                % compute MSE
                Ek = mean(K);
                Ek2 = mean(K.*K);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(K.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                loss = Vr-Ckr*Ckr/Vk;
            elseif K0(rp-j-1) ~= kp-j-1
                K = [K0(1:rp-j-1), kp-j-1, K0(rp-j:end)];
                k_in(i, 4) = kp-j-1;
                r_in(i, 4) = rp-j;
                % compute MSE
                Ek = mean(K);
                Ek2 = mean(K.*K);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(K.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                loss = Vr-Ckr*Ckr/Vk;
            end
    
            if rp+j+1>=n
                Ktmp = [K0, kp+j+1];
                % compute MSE
                Ek = mean(Ktmp);
                Ek2 = mean(Ktmp.*Ktmp);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(Ktmp.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                if Vr-Ckr*Ckr/Vk > loss
                    k_in(i, 4) = kp+j+1;
            	    r_in(i, 4) = bucket_size;
                    loss = Vr-Ckr*Ckr/Vk;
                end
            elseif K0(rp+j+1) ~= kp+j+1
                Ktmp = [K0(1:rp+j), kp+j+1, K0(rp+j+1:end)];
                % compute MSE
                Ek = mean(Ktmp);
                Ek2 = mean(Ktmp.*Ktmp);
                Er = mean(R);
                Er2 = mean(R.*R);
                Ekr = mean(Ktmp.*R);
                Vk = Ek2-Ek*Ek;
                Vr = Er2-Er*Er;
                Ckr = Ekr-Ek*Er;
                if Vr-Ckr*Ckr/Vk > loss
                    k_in(i, 4) = kp+j+1;
                    r_in(i, 4) = rp+j+1;
                    loss = Vr-Ckr*Ckr/Vk;
                end
            end
            dLosses(i, 4) = loss-Loss_arr(i);
        end
    end
    
    % matching rule: (i, 1)+(i+1, 4) and (i, 2)+(i+1, 3)
    
    counter=0;
    poisoning_mask = ones((num_buckets-1), 2);
    while counter < 10000
         counter = counter+1;
        % find largest MSE increment index
        [M, i] = max(poisoning_mask.*(dLosses(1:(end-1), 1:2)+dLosses((2:end), 4:-1:3)));
        [incr, j] = max(M);
        if incr < threshold
            break;
        end
        i = i(j);
        % update array
        if j == 1
            % move poisoning point from ith to i+1th
            poisoned_dataset(i, :) = [poisoned_dataset(i, 1:(r_out(i, 1)-1)), poisoned_dataset(i, (r_out(i, 1)+1):end), k_in(i, 1)];
            poisoned_dataset(i+1, :) =[poisoned_dataset(i+1, 2:(r_in(i+1, 4))), k_in(i+1, 4), poisoned_dataset(i+1, (r_in(i+1, 4)+1):end)];
            poison_num(i) = poison_num(i)-1;
            poison_num(i+1) = poison_num(i+1)+1;
            poison_keys(i+1, poison_num(i+1)) = k_in(i+1, 4);
        elseif j == 2
            % move poisoning point from i+1th to ith
            poisoned_dataset(i, :) = [poisoned_dataset(i, 1:(r_in(i, 2)-1)), k_in(i, 2), poisoned_dataset(i, r_in(i, 2):(end-1))];
            poisoned_dataset(i+1, :) = [k_in(i+1, 3), poisoned_dataset(i+1, 1:(r_out(i+1, 3)-1)), poisoned_dataset(i+1, (r_out(i+1, 3)+1):end)];
            poison_num(i) = poison_num(i)+1;
            poison_num(i+1) = poison_num(i+1)-1;
            poison_keys(i, poison_num(i)) = k_in(i, 2);
        end
        % update params
        Ek_arr(i) = mean(poisoned_dataset(i, :));
        Ek2_arr(i) = (poisoned_dataset(i, :)*poisoned_dataset(i, :)')/bucket_size;
        Ekr_arr(i) = poisoned_dataset(i, :)*(1:bucket_size)'/bucket_size;
        Vk_arr(i) = (Ek2_arr(i))-(Ek_arr(i)*Ek_arr(i));
        Vr_arr(i) = (Er2_arr(i))-(Er_arr(i)*Er_arr(i));
        Ckr_arr(i) = (Ekr_arr(i))-(Ek_arr(i)*Er_arr(i));
        Loss_arr(i) = Vr_arr(i)-(Ckr_arr(i)*Ckr_arr(i))/(Vk_arr(i));
        % update params
        Ek_arr(i+1) = mean(poisoned_dataset(i+1, :));
        Ek2_arr(i+1) = (poisoned_dataset(i+1, :)*poisoned_dataset(i+1, :)')/bucket_size;
        Ekr_arr(i+1) = poisoned_dataset(i+1, :)*(1:bucket_size)'/bucket_size;
        Vk_arr(i+1) = (Ek2_arr(i+1))-(Ek_arr(i+1)*Ek_arr(i+1));
        Vr_arr(i+1) = (Er2_arr(i+1))-(Er_arr(i+1)*Er_arr(i+1));
        Ckr_arr(i+1) = (Ekr_arr(i+1))-(Ek_arr(i+1)*Er_arr(i+1));
        Loss_arr(i+1) = Vr_arr(i+1)-(Ckr_arr(i+1)*Ckr_arr(i+1))/(Vk_arr(i+1));
        % update mask
        poisoning_mask(:, 1) = (poison_num(2:end) < max_poison_num & poison_num(1:(end-1)) > min_poison_num);
        poisoning_mask(:, 2) = (poison_num(1:(end-1)) < max_poison_num & poison_num(2:end) > min_poison_num);
        % update i and i+1 cache
        for i = i:i+1
                if i < num_buckets && poisoning_mask(i, 1)
                    % k_p to next segment
                    k_in(i, 1) = poisoned_dataset(i+1, 1);
                    r_in(i, 1) = bucket_size;
                    k_out(i, 1) = poison_keys(i, poison_num(i));
                    [~, r_out(i, 1)] = min(abs(poisoned_dataset(i, :)-k_out(i, 1)));
                    K = [poisoned_dataset(i, 1:(r_out(i, 1)-1)), poisoned_dataset(i, (r_out(i, 1)+1):end), k_in(i, 1)];
                    R = 1:bucket_size;
                    % update loss
                    Ek = mean(K);
                    Ek2 = mean(K.*K);
                    Er = mean(R);
                    Er2 = mean(R.*R);
                    Ekr = mean(K.*R);
                    Vk = (Ek2)-(Ek*Ek);
                    Vr = (Er2)-(Er*Er);
                    Ckr = (Ekr)-(Ek*Er);
                    loss = Vr-(Ckr*Ckr)/(Vk);
                    dLosses(i, 1) = loss-Loss_arr(i);
                else
                    dLosses(i, 1) = -Inf;
                end
                if i > 1 && poisoning_mask(i-1, 1)
                    % k_p from prev segment
                    k_in(i, 4) = 0;
                    r_in(i, 4) = 0;
                    k_out(i, 4) = poisoned_dataset(i, 1);
                    r_out(i, 4) = 1;
                    K0 = poisoned_dataset(i, 2:end);
                    R = 1:bucket_size;
    
                    % find near empty slot
                    kp = poison_keys(i, max(poison_num(i), 1));
                    [~, rp] = min(abs(K0-kp));
                    j = 0;
                    while rp-j-1>0 && rp+j+1<n && K0(rp-j-1) == kp-j-1 && K0(rp+j+1)== kp+j+1
                        j = j+1;
                    end
                    loss = 0;
                    if rp-j-1<=0
                        K = [kp-j-1, K0];
                        k_in(i, 4) = kp-j-1;
                        r_in(i, 4) = 1;
                        % compute MSE
                        Ek = mean(K);
                        Ek2 = mean(K.*K);
                        Er = mean(R);
                        Er2 = mean(R.*R);
                        Ekr = mean(K.*R);
                        Vk = Ek2-Ek*Ek;
                        Vr = Er2-Er*Er;
                        Ckr = Ekr-Ek*Er;
                        loss = Vr-Ckr*Ckr/Vk;
                    elseif K0(rp-j-1) ~= kp-j-1
                        K = [K0(1:rp-j-1), kp-j-1, K0(rp-j:end)];
                        k_in(i, 4) = kp-j-1;
                        r_in(i, 4) = rp-j;
                        % compute MSE
                        Ek = mean(K);
                        Ek2 = mean(K.*K);
                        Er = mean(R);
                        Er2 = mean(R.*R);
                        Ekr = mean(K.*R);
                        Vk = Ek2-Ek*Ek;
                        Vr = Er2-Er*Er;
                        Ckr = Ekr-Ek*Er;
                        loss = Vr-Ckr*Ckr/Vk;
                    end
    
                    if rp+j+1>=n
                        Ktmp = [K0, kp+j+1];
                        % compute MSE
                        Ek = mean(Ktmp);
                        Ek2 = mean(Ktmp.*Ktmp);
                        Er = mean(R);
                        Er2 = mean(R.*R);
                        Ekr = mean(Ktmp.*R);
                        Vk = Ek2-Ek*Ek;
                        Vr = Er2-Er*Er;
                        Ckr = Ekr-Ek*Er;
                        if Vr-Ckr*Ckr/Vk > loss
                            k_in(i, 4) = kp+j+1;
                            r_in(i, 4) = bucket_size;
                            loss = Vr-Ckr*Ckr/Vk;
                        end
                    elseif K0(rp+j+1) ~= kp+j+1
                        Ktmp = [K0(1:rp+j), kp+j+1, K0(rp+j+1:end)];
                        % compute MSE
                        Ek = mean(Ktmp);
                        Ek2 = mean(Ktmp.*Ktmp);
                        Er = mean(R);
                        Er2 = mean(R.*R);
                        Ekr = mean(Ktmp.*R);
                        Vk = Ek2-Ek*Ek;
                        Vr = Er2-Er*Er;
                        Ckr = Ekr-Ek*Er;
                        if Vr-Ckr*Ckr/Vk > loss
                            k_in(i, 4) = kp+j+1;
                            r_in(i, 4) = rp+j+1;
                            loss = Vr-Ckr*Ckr/Vk;
                        end
                    end
                    dLosses(i, 4) = loss-Loss_arr(i);
                else
                    dLosses(i, 4) = -Inf;
                end
                if i < num_buckets && poisoning_mask(i, 2)
                    % k_p from next segment
                    % find k_in as a new poison point
                    k_in(i, 2) = 0;
                    r_in(i, 2) = 0;
                    k_out(i, 2) = poisoned_dataset(i, bucket_size);
                    r_out(i, 2) = bucket_size;
                    K0 = poisoned_dataset(i, 1:(end-1));
                    R = 1:bucket_size;
    
                    % find near empty slot
                    kp = poison_keys(i, max(poison_num(i), 1));
                    [~, rp] = min(abs(K0-kp));
                    j = 0;
                    while rp-j-1>0 && rp+j+1<n && K0(rp-j-1) == kp-j-1 && K0(rp+j+1)== kp+j+1
                        j = j+1;
                    end
                    loss = 0;
                    if rp-j-1<=0
                        K = [kp-j-1, K0];
                        R = 1:bucket_size;
                        k_in(i, 2) = kp-j-1;
                        r_in(i, 2) = 1;
                        % compute MSE
                        Ek = mean(K);
                        Ek2 = mean(K.*K);
                        Er = mean(R);
                        Er2 = mean(R.*R);
                        Ekr = mean(K.*R);
                        Vk = Ek2-Ek*Ek;
                        Vr = Er2-Er*Er;
                        Ckr = Ekr-Ek*Er;
                        loss = Vr-Ckr*Ckr/Vk;
                    elseif K0(rp-j-1) ~= kp-j-1
                        K = [K0(1:rp-j-1), kp-j-1, K0(rp-j:end)];
                        k_in(i, 2) = kp-j-1;
                        r_in(i, 2) = rp-j;
                        % compute MSE
                        Ek = mean(K);
                        Ek2 = mean(K.*K);
                        Er = mean(R);
                        Er2 = mean(R.*R);
                        Ekr = mean(K.*R);
                        Vk = Ek2-Ek*Ek;
                        Vr = Er2-Er*Er;
                        Ckr = Ekr-Ek*Er;
                        loss = Vr-Ckr*Ckr/Vk;
                    end
    
                    if rp+j+1>=n
                        Ktmp = [K0, kp+j+1];
                        % compute MSE
                        Ek = mean(Ktmp);
                        Ek2 = mean(Ktmp.*Ktmp);
                        Er = mean(R);
                        Er2 = mean(R.*R);
                        Ekr = mean(Ktmp.*R);
                        Vk = Ek2-Ek*Ek;
                        Vr = Er2-Er*Er;
                        Ckr = Ekr-Ek*Er;
                        if Vr-Ckr*Ckr/Vk > loss
                            k_in(i, 2) = kp+j+1;
                            r_in(i, 2) = bucket_size;
                            loss = Vr-Ckr*Ckr/Vk;
                        end
                    elseif K0(rp+j+1) ~= kp+j+1
                        Ktmp = [K0(1:rp+j), kp+j+1, K0(rp+j+1:end)];
                        % compute MSE
                        Ek = mean(Ktmp);
                        Ek2 = mean(Ktmp.*Ktmp);
                        Er = mean(R);
                        Er2 = mean(R.*R);
                        Ekr = mean(Ktmp.*R);
                        Vk = Ek2-Ek*Ek;
                        Vr = Er2-Er*Er;
                        Ckr = Ekr-Ek*Er;
                        if Vr-Ckr*Ckr/Vk > loss
                            k_in(i, 2) = kp+j+1;
                            r_in(i, 2) = rp+j+1;
                            loss = Vr-Ckr*Ckr/Vk;
                        end
                    end
    
                    %update loss
                    dLosses(i, 2) = loss-Loss_arr(i);
                else
                    dLosses(i, 2) = -Inf;
                end
                if i > 1 && poisoning_mask(i-1, 2)
                    % k_p to prev segment
                    k_in(i, 3) = poisoned_dataset(i-1, bucket_size);
                    r_in(i, 3) = 1;
                    k_out(i, 3) = poison_keys(i, poison_num(i));
                    [~, r_out(i, 3)] = min(abs(poisoned_dataset(i, :)-k_out(i, 3)));
                    K = [k_in(i, 3), poisoned_dataset(i, 1:(r_out(i, 3)-1)), poisoned_dataset(i, (r_out(i, 3)+1):end)];
                    R = 1:bucket_size;
                    % update loss
                    Ek = mean(K);
                    Ek2 = mean(K.*K);
                    Er = mean(R);
                    Er2 = mean(R.*R);
                    Ekr = mean(K.*R);
                    Vk = (Ek2)-(Ek*Ek);
                    Vr = (Er2)-(Er*Er);
                    Ckr = (Ekr)-(Ek*Er);
                    loss = Vr-(Ckr*Ckr)/(Vk);
                    dLosses(i, 3) = loss-Loss_arr(i);
                else
                    dLosses(i, 3) = -Inf;
                end
        end
    end
    
    % lad
    Loss_lad = zeros(1, num_buckets);
    Loss_lad_max = zeros(1, num_buckets);
    Loss_lad_var = zeros(1, num_buckets);
    for bnm = 1:num_buckets
        K = poisoned_dataset(bnm, :);
        R = 1:bucket_size;
        Ek = mean(K);
        Ek2 = mean(K.*K);
        Er = mean(R);
        Ekr = mean(K.*R);
        Vk = Ek2-Ek*Ek;
        Ckr = Ekr-Ek*Er;
        w = Ckr/Vk;
        b = Er-w*Ek;
        for idx = R
            Loss_lad(bnm) = Loss_lad(bnm) + abs(w*K(idx)+b-idx);
            Loss_lad_max(bnm) = max(Loss_lad_max(bnm), abs(w*K(idx)+b-idx));
        end
        Loss_lad(bnm) = Loss_lad(bnm)/R(end);
    
        for idx = R
            Loss_lad_var(bnm) = Loss_lad_var(bnm) + (abs(w*K(idx)+b-idx)-Loss_lad(bnm))^2;
        end
        Loss_lad_var(bnm) = Loss_lad_var(bnm)/R(end);
    end
end
