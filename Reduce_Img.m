%% 光场数据降采样（从 15×15 到 9×9）
clc; clear;

% ========== 1. 加载光场图像 ==========

disp('加载光场图像...');
TargetFile = './LightField_Data/results/shifted_images_Integer/Shifted_sample_Integer.tif'; % 原始 15×15 的 TIFF 文件
View_Num_Original = 15; % 原始视角阵列尺寸
View_Num_New = 9; % 新视角阵列尺寸

% 加载原始 15×15 TIFF 文件
Volume = tiffreadVolume(TargetFile); % 加载为 3D 矩阵
[row, col, num_views] = size(Volume); % 获取光场尺寸

% 检查视角数量是否正确
if num_views ~= View_Num_Original^2
    error('视角数量与原始微透镜阵列尺寸不匹配，请检查输入数据！');
end

% 将光场数据从 3D 转换为 4D（[row, col, u, v]）
New_Image = reshape(Volume, row, col, View_Num_Original, View_Num_Original);

% ========== 2. 提取中心的 9×9 视角区域 ==========

disp('提取中心的 9×9 视角区域...');
center_idx = (View_Num_Original + 1) / 2; % 中心视角的索引（8 对应 15×15）
half_new = (View_Num_New - 1) / 2;

% 计算 9×9 区域在 15×15 中的索引范围
start_idx = center_idx - half_new;
end_idx = center_idx + half_new;

% 提取 9×9 的视角区域
Reduced_Image = New_Image(:, :, start_idx:end_idx, start_idx:end_idx);

% 确认结果
[row_new, col_new, u_new, v_new] = size(Reduced_Image);
if u_new ~= View_Num_New || v_new ~= View_Num_New
    error('提取的视角区域尺寸与目标尺寸不匹配，请检查代码！');
end

disp('中心的 9×9 视角区域提取完成！');

% ========== 3. 保存降采样后的光场数据为新的 TIFF 文件 ==========

disp('保存降采样后的光场数据为 TIFF 文件...');
output_folder = './LightField_Data/results/reduced_images/';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
output_file = fullfile(output_folder, 'Realign_Image_9x9.tif');

% 将 4D 数据转换回 3D 并保存为 TIFF 文件
for u = 1:View_Num_New
    for v = 1:View_Num_New
        Current_Image = Reduced_Image(:, :, u, v); % 当前视角图像
        if u == 1 && v == 1
            imwrite(Current_Image, output_file); % 写入第一层
        else
            imwrite(Current_Image, output_file, 'WriteMode', 'append'); % 追加写入其余层
        end
    end
end

disp(['降采样后的光场数据已保存至: ', output_file]);
