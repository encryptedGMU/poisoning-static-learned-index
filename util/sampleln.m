%  For any number [range], randomly sample [num] numbers within [0, range].
%  The sampling distribution is log-normal distribution sigma value [1]
%  and mu value [-ln(50)]. Repeating instances and out-of-range instances
%  are discarded.
function d = sampleln(range, num)
    d = [];
    while size(d, 2) < num
        tmp = round(exp(normrnd(0, 1, [1, num]))*range/50);
        d = unique([d, tmp]);
        d = d(d>0 & d<range);
    end
    d = datasample(d, num, 'Replace', false);
    d = sort(d);
end