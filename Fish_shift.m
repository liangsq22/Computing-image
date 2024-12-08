clc; clear;

% ========== 1. 加载偏移量 ========== 
disp('加载偏移量数据...');
load('./LightField_Data/results/shift_map_Integer.mat'); % 加载偏移量文件 shift_map_Integer.mat

% ========== 2. 加载新的光场图像 ========== 
disp('加载新的光场图像...');
TargetFile = './LightField_Data/video/results/Realign_Image_1.tif'; % 新的图像文件
Volume = tiffreadVolume(TargetFile); % 加载新的图像
[row, col, num_views] = size(Volume); % 获取图像尺寸
View_Num = 15; % 微透镜阵列的尺寸 (15×15)
New_Image = reshape(Volume, row, col, View_Num, View_Num); % 转换为 4D 矩阵

% ========== 3. 根据偏移量对新的图像进行平移 ========== 
disp('根据偏移量对新的光场图像进行平移...');

% 初始化平移后的光场图像存储
shifted_New_Image = zeros(size(New_Image));

% 创建坐标网格
[X, Y] = meshgrid(1:col, 1:row); % 原始坐标

for u = 1:View_Num
    for v = 1:View_Num
        % 提取当前视角图像和对应的偏移量
        Current_Image = squeeze(New_Image(:, :, u, v));
        dx = shift_map(u, v, 1); % 获取偏移量 dx
        dy = shift_map(u, v, 2); % 获取偏移量 dy

        % 计算新的坐标
        shifted_X = X + dx;
        shifted_Y = Y + dy;

        % 使用interp2进行cubic插值平移
        shifted_New_Image(:, :, u, v) = interp2(X, Y, single(Current_Image), shifted_X, shifted_Y, 'cubic', 0);

        fprintf('视角 (u=%d, v=%d): 完成平移\n', u, v);
    end
end

shifted_New_Image = shifted_New_Image / max(shifted_New_Image(:)); % 归一化图像

disp('所有视角的图像平移完成！');

% ========== 4. 保存平移后的光场数据 ========== 
disp('保存平移后的光场数据...');

shifted_output_folder = './LightField_Data/video/';
if ~exist(shifted_output_folder, 'dir')
    mkdir(shifted_output_folder); % 如果不存在则创建文件夹
end

% 保存平移后的图像
TargetFile_1 = fullfile(shifted_output_folder, 'Shifted_Image.tif');

for j = 1:View_Num
    for i = 1:View_Num
        if i == 1 && j == 1
            imwrite(shifted_New_Image(:, :, i, j), TargetFile_1);
        else
            imwrite(shifted_New_Image(:, :, i, j), TargetFile_1, 'Writemode', 'append');
        end
    end
end

disp('平移后的光场数据已保存！');
