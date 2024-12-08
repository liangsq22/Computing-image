clc; clear;

% ========== 1. 配置路径和加载文件 ==========
inputFile = './LightField_Data/results/3D_Reconstructed_Image_81_3_TV.tif'; % 输入 TIFF 文件路径
outputFile = './LightField_Data/results/Smoothed_3D_Reconstructed_Image.tif'; % 输出 TIFF 文件路径

% 读取 TIFF 文件为 3D 数据
Volume = tiffreadVolume(inputFile);
[row, col, num_slices] = size(Volume); % 获取图像的尺寸和切片数量

% ========== 2. 定义平滑处理 ==========
disp('开始进行平滑处理...');
sigma = 1.5; % 高斯滤波器的标准差，可以根据需要调整
smoothedVolume = zeros(size(Volume), 'single'); % 初始化平滑结果矩阵

% 对每一层图像进行平滑处理
for i = 1:num_slices
    slice = Volume(:,:,i); % 提取当前切片
    smoothedVolume(:,:,i) = imgaussfilt(slice, sigma); % 对每一层应用高斯滤波
end

% ========== 3. 保存平滑后的结果 ==========
disp('保存平滑后的图像...');
% 保存为新的 TIFF 文件
imwriteTFSK(uint8(smoothedVolume), outputFile);

disp(['平滑后的图像已保存至: ' outputFile]);
