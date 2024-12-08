%% DAO数字自适应光学：shift整数版本
clc; clear;

% ========== 1. 加载光场图像 ========== 
disp('加载光场图像...');
TargetFile1 = './LightField_Data/results/Realign_Image_cross.tif'; % 十字图像文件
TargetFile2 = './LightField_Data/results/Realign_Image.tif'; % 样本图像文件
View_Num = 15; % 微透镜阵列的尺寸 (15×15)
Volume_1 = tiffreadVolume(TargetFile1); % 加载十字图像
Volume_2 = tiffreadVolume(TargetFile2); % 加载样本图像
[row, col, num_views] = size(Volume_1); % 获取光场尺寸
Cross_Image = reshape(Volume_1, row, col, View_Num, View_Num); % 转换为 4D 矩阵
Sample_Image = reshape(Volume_2, row, col, View_Num, View_Num); % 转换为 4D 矩阵

% 定义中心视角
center_u = 8; % 中心视角的 u 坐标
center_v = 8; % 中心视角的 v 坐标
Center_Image = squeeze(Cross_Image(:, :, center_u, center_v)); % 中心视角图像 (2D)
shift_map = zeros(View_Num, View_Num, 2); % 偏移量映射 (u, v, [dx, dy])

% ========== 2. 对每个视角图像求互相关 ========== 
disp('计算视角间的偏移量...');
Reference_Image = squeeze(Cross_Image(:, :, 8, 8)); % 中心视角 (8, 8)

% 设置互相关计算的搜索窗口大小 (例如：一个5x5区域)
search_window_size = 5;
half_window = floor(search_window_size / 2);

for u = 1:View_Num
    for v = 1:View_Num
        Current_Image = squeeze(Cross_Image(:, :, u, v)); % 当前视角图像 (2D)

        % 限制计算互相关的区域：选择图像中心区域
        x_min = max(1, center_u - half_window);
        x_max = min(View_Num, center_u + half_window);
        y_min = max(1, center_v - half_window);
        y_max = min(View_Num, center_v + half_window);

        % 截取视角图像和参考图像的子区域
        region_ref = Reference_Image(x_min:x_max, y_min:y_max);
        region_current = Current_Image(x_min:x_max, y_min:y_max);

        % 计算互相关
        cross_corr = normxcorr2(region_ref, region_current); % 归一化互相关
        [max_corr, max_idx] = max(cross_corr(:)); % 找到互相关的最大值
        [peak_y, peak_x] = ind2sub(size(cross_corr), max_idx); % 获取互相关峰值的位置

        % 计算偏移量 (相对于中心视角)
        dx = peak_x - size(region_current, 2); % 横向偏移
        dy = peak_y - size(region_current, 1); % 纵向偏移

        % 存储偏移量
        shift_map(u, v, :) = [dx, dy];
        fprintf('视角 (u=%d, v=%d): 偏移量 dx=%.2f, dy=%.2f\n', u, v);
    end
end

% ========== 3. 保存偏移量shift值 ========== 
disp('保存视角间的偏移量...');
output_folder = './LightField_Data/results'; % 设置保存文件夹路径
if ~exist(output_folder, 'dir')
    mkdir(output_folder); % 如果不存在则创建文件夹
end
output_file = fullfile(output_folder, 'shift_map_Integer.mat'); % 拼接文件路径
save(output_file, 'shift_map');
disp(['偏移量计算完成并已保存至: ', output_file]);

% ========== 4. 根据偏移量对十字和样本图像进行平移 ========== 
disp('根据偏移量对光场图像进行平移...');

% 初始化平移后的光场图像存储
shifted_Image_cross = zeros(size(Cross_Image));
shifted_Image_sample = zeros(size(Sample_Image));

% 创建坐标网格
[X, Y] = meshgrid(1:col, 1:row); % 原始坐标

for u = 1:View_Num
    for v = 1:View_Num
        % 提取当前视角图像和对应的偏移量
        Current_Image_cross = squeeze(Cross_Image(:, :, u, v));
        Current_Image_sample = squeeze(Sample_Image(:, :, u, v));
        dx = shift_map(u, v, 1);
        dy = shift_map(u, v, 2);

        % 计算新的坐标
        shifted_X = X + dx;
        shifted_Y = Y + dy;

        % 使用interp2进行cubic插值平移（十字叉和样本图像）
        shifted_Image_cross(:, :, u, v) = interp2(X, Y, single(Current_Image_cross), shifted_X, shifted_Y, 'cubic', 0);
        shifted_Image_sample(:, :, u, v) = interp2(X, Y, single(Current_Image_sample), shifted_X, shifted_Y, 'cubic', 0);

        fprintf('视角 (u=%d, v=%d): 完成平移\n', u, v);
    end
end

shifted_Image_cross = shifted_Image_cross / max(shifted_Image_cross(:));
shifted_Image_sample = shifted_Image_sample / max(shifted_Image_sample(:));

disp('所有视角的图像平移完成！');

% ========== 5. 保存平移后的光场数据 ========== 
disp('保存平移后的光场数据...');

shifted_output_folder = './LightField_Data/results/shifted_images_Integer';
if ~exist(shifted_output_folder, 'dir')
    mkdir(shifted_output_folder); % 如果不存在则创建文件夹
end

% 保存平移后的十字图像
%TargetFile_1 = fullfile(shifted_output_folder, 'Shifted_cross_Integer.tif');
%TargetFile_2 = fullfile(shifted_output_folder, 'Shifted_sample_Integer.tif');

% for j = 1:View_Num
%     for i = 1:View_Num
%         if i == 1 && j == 1
%             imwrite(shifted_Image_cross(:, :, i, j), TargetFile_1);
%             imwrite(shifted_Image_sample(:, :, i, j), TargetFile_2);
%         else
%             imwrite(shifted_Image_cross(:, :, i, j), TargetFile_1, 'Writemode', 'append');
%             imwrite(shifted_Image_sample(:, :, i, j), TargetFile_2, 'Writemode', 'append');
%         end
%     end
% end

disp('平移后的光场数据已保存！');
