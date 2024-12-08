%% TIFF文件图像处理：降低亮度
clc; clear;

% ========== 配置路径 ==========
inputTiffPath = './LightField_Data/results/3D_Reconstructed_Image_81_3.tif'; % 输入 TIFF 文件路径
outputTiffPath = './LightField_Data/results/Test_Darker.tif'; % 输出 TIFF 文件路径

% ========== 读取 TIFF 文件 ==========
disp('读取 TIFF 文件...');
tiffInfo = imfinfo(inputTiffPath); % 获取 TIFF 文件信息
numFrames = numel(tiffInfo); % 获取帧数

% ========== 逐帧处理 ==========
disp('逐帧处理并保存...');
for i = 1:numFrames
    % 读取当前帧
    currentFrame = imread(inputTiffPath, i);
    
    % 转换为双精度以进行数学运算
    currentFrameDouble = im2double(currentFrame);
    
    % 亮度降低至原来的一半
    darkerFrame = currentFrameDouble * 1.05;
    
    % 转换为 uint8，根据原图像类型
    darkerFrameUint = im2uint8(darkerFrame);
    
    % 保存为新的 TIFF 文件
    if i == 1
        imwrite(darkerFrameUint, outputTiffPath); % 第一帧写入
    else
        imwrite(darkerFrameUint, outputTiffPath, 'WriteMode', 'append'); % 追加写入
    end
    
    fprintf('帧 %d/%d 已处理完成。\n', i, numFrames);
end

disp(['处理完成，已保存至: ', outputTiffPath]);
