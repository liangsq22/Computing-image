%% 读取TIFF文件中特定帧的像素强度值
clc; clear;

% ========== 配置路径 ==========
tiffFilePath = './LightField_Data/results/3D_Reconstructed_Image.tif'; % TIFF 文件路径
OnePath = './LightField_Data/results/refcous_imgs/3_refocused_image_alpha_0.014.bmp'; %单张
frameNumber = 21; % 要读取的帧编号（从 1 开始）

% ========== 读取指定帧 ==========
disp(['读取TIFF文件: ', tiffFilePath]);

% 使用 imfinfo 检查TIFF文件的信息
info = imfinfo(tiffFilePath);
numFrames = numel(info);

% 检查帧编号是否有效
if frameNumber < 1 || frameNumber > numFrames
    error('帧编号超出范围！文件共有 %d 帧。', numFrames);
end

% 读取指定帧
frameData = imread(tiffFilePath, frameNumber);
%frameData = imread(OnePath);

% ========== 输出像素强度值 ==========
disp(['读取帧编号: ', num2str(frameNumber)]);
disp('像素强度值矩阵:');
disp(frameData);

% ========== 可视化读取的帧（可选） ==========
figure;
imshow(frameData, []);
title(['帧编号: ', num2str(frameNumber)]);
