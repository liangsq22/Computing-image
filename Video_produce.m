clc; clear;

% 配置参数
inputTIFFPath = './LightField_Data/video/New2_Video_Realign_View200_E_05_Iter_0525_output.tif'; % 输入的tiff文件路径
outputAVIPath1 = './LightField_Data/video/Output2_Video_upsample.avi'; % 输出的上采样avi视频文件路径
outputAVIPath2 = './LightField_Data/video/Output2_Video.avi'; % 输出的下采样avi视频文件路径
outputDownsampleTIFF = './LightField_Data/video/Output2_Downsample.tif'; % 输出的下采样tiff文件路径
outputUpsampleBMP = './LightField_Data/video/Output2_First_Upsample.bmp'; % 输出的上采样第一帧bmp
outputDownsampleBMP = './LightField_Data/video/Output2_First_Downsample.bmp'; % 输出的下采样第一帧bmp

% 获取TIFF文件信息
info = imfinfo(inputTIFFPath);
numFrames = numel(info); % 获取tiff中的帧数

% 检查是否有500帧
if numFrames ~= 500
    error('输入的TIFF文件必须包含500帧');
end

% 创建VideoWriter对象，设置视频帧率（例如20帧每秒）
fps = 20; % 帧率可以根据需要调整

% ========= 上采样视频 =========
v_upsample = VideoWriter(outputAVIPath1, 'Uncompressed AVI');
v_upsample.FrameRate = fps;
open(v_upsample);  % 打开视频写入

% 读取并写入每一帧（上采样后的直接转换）
for idx = 1:numFrames
    % 读取当前帧图像
    img = imread(inputTIFFPath, idx);

    % 如果图像是16位的
    if isa(img, 'uint16')
        % 确保图像数据在 [0, 1] 范围内
        img = double(img);  % 转换为双精度浮点数
        img = img - min(img(:));  % 去除最小值，使最小值为零
        img = img / max(img(:));  % 归一化到 [0, 1] 范围
        % 然后将归一化后的图像转为8位
        img = uint8(img * 255);  % 映射到 [0, 255] 并转换为 uint8
    end

    % 将图像写入视频
    writeVideo(v_upsample, img);

    disp(['处理上采样视频，第 ', num2str(idx), ' 帧']);
end

% 关闭上采样视频文件
close(v_upsample);
disp(['上采样视频已保存至: ', outputAVIPath1]);

% ========= 下采样视频 =========
v_downsample = VideoWriter(outputAVIPath2, 'Uncompressed AVI');
v_downsample.FrameRate = fps;
open(v_downsample);  % 打开视频写入

% 读取并写入每一帧（下采样后的转换）
for idx = 1:numFrames
    % 读取当前帧图像
    img = imread(inputTIFFPath, idx);

    % 如果图像是16位的
    if isa(img, 'uint16')
        % 确保图像数据在 [0, 1] 范围内
        img = double(img);  % 转换为双精度浮点数
        img = img - min(img(:));  % 去除最小值，使最小值为零
        img = img / max(img(:));  % 归一化到 [0, 1] 范围
        % 然后将归一化后的图像转为8位
        img = uint8(img * 255);  % 映射到 [0, 255] 并转换为 uint8
    end

    % 先进行高斯滤波以平滑图像，减少高频噪声
    smoothedImage = imgaussfilt(img, 0.5); % 0.5是标准差，可以根据需要调整

    % 下采样7倍
    downsampledImage = imresize(smoothedImage, 1/7); % 7倍下采样

    % 将下采样后的图像写入视频
    writeVideo(v_downsample, downsampledImage);

    % 将下采样图像保存为TIFF文件
    if idx == 1
        imwrite(downsampledImage, outputDownsampleTIFF, 'WriteMode', 'overwrite');
        imwrite(downsampledImage, outputDownsampleBMP); % 保存第一帧为BMP
    else
        imwrite(downsampledImage, outputDownsampleTIFF, 'WriteMode', 'append');
    end

    disp(['处理下采样视频，第 ', num2str(idx), ' 帧']);
end

% 关闭下采样视频文件
close(v_downsample);
disp(['下采样视频已保存至: ', outputAVIPath2]);
disp(['下采样TIFF已保存至: ', outputDownsampleTIFF]);
disp(['第一帧上采样BMP已保存至: ', outputUpsampleBMP]);
disp(['第一帧下采样BMP已保存至: ', outputDownsampleBMP]);
