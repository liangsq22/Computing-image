clc; clear;

% ========== 配置参数 ==========
inputTIFFPath = './LightField_Data/video/Selected_Views.tif'; % 输入的tiff文件路径
inputBMPPath = './LightField_Data/video/Output2_First_Downsample.bmp'; % 输入的bmp文件路径
outputTIFFPath = './LightField_Data/video/3D/Selected_Views_Combined.tif'; % 输出的tiff文件路径
weightTIFF = 0.65; % tiff帧的权重
weightBMP = 0.35; % bmp图像的权重
maxBrightnessFactor = 3; % 右下角的最大亮度提升因子
minBrightnessFactor = 1; % 图像中心的亮度因子

% ========== 加载 BMP 图像 ==========
disp('加载 BMP 图像...');
bmpImage = imread(inputBMPPath);

% 检查 BMP 是否为单通道灰度图像或转换为灰度
if size(bmpImage, 3) == 3
    disp('输入的 BMP 图像为彩色图像，转换为灰度图像...');
    bmpImage = rgb2gray(bmpImage);
end

bmpImage = im2double(bmpImage); % 转为双精度浮点数，便于计算

% ========== 对 BMP 的全图进行平滑亮度增强 ==========
disp('对 BMP 图像进行平滑亮度增强...');
[row, col] = size(bmpImage); % 获取图像尺寸

% 计算图像的中心点和右下角
centerX = col / 2; % 图像中心 X 坐标
centerY = row / 2; % 图像中心 Y 坐标

% 创建距离矩阵
[X, Y] = meshgrid(1:col, 1:row); % 坐标网格
distanceMatrix = sqrt((X - col).^2 + (Y - row).^2); % 到右下角的欧几里得距离
maxDistance = sqrt((centerX - col)^2 + (centerY - row)^2); % 中心点到右下角的距离

% 计算权重矩阵
weightMatrix = (distanceMatrix / maxDistance) * (minBrightnessFactor - maxBrightnessFactor) + maxBrightnessFactor;
weightMatrix(weightMatrix < minBrightnessFactor) = minBrightnessFactor; % 限制权重不低于 1

% 增强全图亮度
brightenedImage = bmpImage .* weightMatrix;

% 确保亮度值不会超过最大值 1
brightenedImage(brightenedImage > 1) = 1;

% ========== 加载 TIFF 文件 ==========
disp('加载 TIFF 文件...');
info = imfinfo(inputTIFFPath);
numFrames = numel(info); % 获取 TIFF 文件的帧数
[row, col] = size(imread(inputTIFFPath, 1)); % 获取单帧尺寸

% 检查 BMP 尺寸是否与 TIFF 帧一致
if size(brightenedImage, 1) ~= row || size(brightenedImage, 2) ~= col
    error('BMP 图像尺寸与 TIFF 文件每帧的尺寸不一致，请调整 BMP 图像大小。');
end

% ========== 合成每一帧 ==========
disp('开始逐帧合成处理...');
for idx = 1:numFrames
    % 读取当前帧
    tiffFrame = imread(inputTIFFPath, idx);
    
    % 如果 TIFF 帧是 16 位，转换为双精度浮点数
    if isa(tiffFrame, 'uint16')
        tiffFrame = double(tiffFrame) / 65535; % 转为 [0, 1] 范围
    else
        tiffFrame = im2double(tiffFrame); % 转为双精度浮点数
    end

    % 合成当前帧与增强后的 BMP 图像
    combinedFrame = tiffFrame * weightTIFF + brightenedImage * weightBMP;

    % 对合成结果进行归一化，确保结果在 [0, 1] 范围内
    combinedFrame = mat2gray(combinedFrame);

    % 保存合成帧到新 TIFF 文件
    if idx == 1
        imwrite(uint8(combinedFrame * 255), outputTIFFPath, 'WriteMode', 'overwrite'); % 第一帧覆盖保存
    else
        imwrite(uint8(combinedFrame * 255), outputTIFFPath, 'WriteMode', 'append'); % 追加后续帧
    end

    disp(['已完成第 ', num2str(idx), ' 帧合成处理']);
end

disp(['合成后的 TIFF 文件已保存至: ', outputTIFFPath]);

