% Specialized function for plotting
function make_plots(data_size_pool, density_pool, out_arr, out_arr_lad, ...
    out_arr_lad_max, out_arr_lad_var)
% dimension 1: iteration 1-20
% dimension 2: num_points 100 500 1000 5000
% dimension 3: density 5 10 50 80
% dimension 4: mse instances (17, 81, 161, 801)
figure(1);
lims = [1, 15; 1, 50; 1, 100; 1, 500];
% ticks for graphs
y_ticks = [0:2:20;0:6:60;0:10:100;0:50:500];
y_minor_ticks = [0:0.2:20;0:0.6:60;0:1:100;0:5:500];
% align the graphs
x_in_pos = [0.1300, 0.3361, 0.5422, 0.7483];
y_in_pos = [0.7673, 0.5482, 0.3291, 0.1100];
in_const3 = [0.1766, 0.1766, 0.1766, 0.1766];
in_const4 = [0.1777, 0.1777, 0.1777, 0.1777];
ln_out = out_arr;

for j = 1:4
    for k = 1:4
        tmp = ln_out(:, :, j, k);
        ax = subplot(4, 4, (j-1)*4+k);
        ax.Position = [x_in_pos(k), y_in_pos(j), in_const3(j), in_const4(k)];
        boxplot(tmp(:, 3:3:15), 'Labels', 3:3:15, 'Jitter', 1, 'Symbol', '');
        set(gca,'FontSize',14);
        xlabel('Poisoning Percentage', 'FontSize', 16);
        ylabel("Ratio Loss", 'FontSize', 20);
        title("Keys: " + data_size_pool(j) + "Domain:" + data_size_pool(j)/density_pool(k), 'FontSize', 15);
        ylim(lims(j, :));
        xticks(1:16);
        yticks(y_ticks(j, :));
        ax.YAxis.MinorTick = 'on';
        ax.YAxis.MinorTickValues = y_minor_ticks(j, :);
        grid on;
    end
    ylim(lims(j, :))
end

figure(2);
lims = [1, 10; 1, 30; 1, 50; 1, 200];
% ticks for graphs
y_ticks = [0:2:10;0:6:30;0:10:50;0:50:250];
y_minor_ticks = [0:0.2:10;0:0.6:30;0:1:50;0:5:250];
% align the graphs
x_in_pos = [0.1300, 0.3361, 0.5422, 0.7483];
y_in_pos = [0.7673, 0.5482, 0.3291, 0.1100];
in_const3 = [0.1766, 0.1766, 0.1766, 0.1766];
in_const4 = [0.1777, 0.1777, 0.1777, 0.1777];
ln_out_lad = out_arr_lad;
for j = 1:4
    for k = 1:4
        tmp = ln_out_lad(:, :, j, k);
        ax = subplot(4, 4, (j-1)*4+k);
        ax.Position = [x_in_pos(k), y_in_pos(j), in_const3(j), in_const4(k)];
        boxplot(tmp(:, 3:3:15), 'Labels', 3:3:15, 'Jitter', 1, 'Symbol', '');
        set(gca,'FontSize',14);
        xlabel('Poisoning Percentage', 'FontSize', 16);
        ylabel("Average Memory Offset", 'FontSize', 15);
        title("Keys: " + data_size_pool(j) + " Domain:" + data_size_pool(j)/density_pool(k), 'FontSize', 15);
        ylim(lims(j, :));
        xticks(1:16);
        yticks(y_ticks(j, :));
        ax.YAxis.MinorTick = 'on';
        ax.YAxis.MinorTickValues = y_minor_ticks(j, :);
        grid on;
    end
end

figure(3);
lims = [1, 20; 1, 50; 1, 100; 1, 500];
% ticks for graphs
y_ticks = [0:4:20;0:12:60;0:20:100;0:100:500];
y_minor_ticks = [0:0.4:20;0:1.2:60;0:2:100;0:10:500];
% align the graphs
x_in_pos = [0.1300, 0.3361, 0.5422, 0.7483];
y_in_pos = [0.7673, 0.5482, 0.3291, 0.1100];
in_const3 = [0.1766, 0.1766, 0.1766, 0.1766];
in_const4 = [0.1777, 0.1777, 0.1777, 0.1777];
ln_out_lad_max = out_arr_lad_max;
for j = 1:4
    for k = 1:4
        tmp = ln_out_lad_max(:, :, j, k);
        ax = subplot(4, 4, (j-1)*4+k);
        ax.Position = [x_in_pos(k), y_in_pos(j), in_const3(j), in_const4(k)];
        boxplot(tmp(:, 3:3:15), 'Labels', 3:3:15, 'Jitter', 1, 'Symbol', '');
        set(gca,'FontSize',14);
        xlabel('Poisoning Percentage', 'FontSize', 16);
        ylabel("Max Memory Offset", 'FontSize', 15);
        title("Keys: " + data_size_pool(j) + " Domain:" + data_size_pool(j)/density_pool(k), 'FontSize', 15);
        ylim(lims(j, :));
        xticks(1:16);
        yticks(y_ticks(j, :));
        ax.YAxis.MinorTick = 'on';
        ax.YAxis.MinorTickValues = y_minor_ticks(j, :);
        grid on;
    end
end

figure(4);
% align the graphs
x_in_pos = [0.1300, 0.3361, 0.5422, 0.7483];
y_in_pos = [0.7673, 0.5482, 0.3291, 0.1100];
in_const3 = [0.1766, 0.1766, 0.1766, 0.1766];
in_const4 = [0.1777, 0.1777, 0.1777, 0.1777];
ln_out_lad_var = out_arr_lad_var;
for j = 1:4
    for k = 1:4
        tmp = ln_out_lad_var(:, :, j, k);
        ax = subplot(4, 4, (j-1)*4+k);
        ax.Position = [x_in_pos(k), y_in_pos(j), in_const3(j), in_const4(k)];
        boxplot(tmp(:, 3:3:15), 'Labels', 3:3:15, 'Jitter', 1, 'Symbol', '');
        set(gca,'FontSize',14);
        xlabel('Poisoning Percentage', 'FontSize', 16);
        ylabel("Variance of Memory Offset", 'FontSize', 15);
        title("Keys: " + data_size_pool(j) +" Domain:" + data_size_pool(j)/density_pool(k), 'FontSize', 15);
        ax.YAxis.MinorTick = 'on';
        grid on;
    end
end


