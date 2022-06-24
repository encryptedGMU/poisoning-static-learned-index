%  For any number [range], randomly sample [num] numbers within [0, range].
%  The sampling distribution is normal distribution with mean [range/2]
%  and variance [range/3]. Repeating instances and out-of-range instances
%  are discarded.
function d = samplenormal(range, num)
    d = [];
    while size(d, 2) < num
        tmp = round(normrnd(0, 1, [1, num])*range/3+range/2);
        d = unique([d, tmp]);
        d = d(d>0 & d<range);
    end
    d = datasample(d, num, 'Replace', false);
    d = sort(d);
end