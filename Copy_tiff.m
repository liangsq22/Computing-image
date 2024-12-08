%% 图像复制并保存为41帧TIFF文件
clc; clear;

% ========== 配置路径 ==========
inputImagePath1 = './LightField_Data/results/upsampled_image_alpha_0.000.bmp'; % 第一张输入图像路径
inputImagePath2 = './LightField_Data/results/upsampled_image_alpha_0.100.bmp'; % 第二张输入图像路径
outputTiffPath1 = './LightField_Data/results/output_image1.tif';  % 第一张图像的输出TIFF路径
outputTiffPath2 = './LightField_Data/results/output_image2.tif';  % 第二张图像的输出TIFF路径
numFrames = 41; % 每张图像复制的帧数

% ========== 1. 加载图像 ==========
disp('加载图像...');
image1 = imread(inputImagePath1);
image2 = imread(inputImagePath2);

% 检查图像是否为灰度图像，如果不是，转换为灰度图像
if size(image1, 3) == 3
    disp('第一张图像为彩色图像，转换为灰度图像...');
    image1 = rgb2gray(image1);
end
if size(image2, 3) == 3
    disp('第二张图像为彩色图像，转换为灰度图像...');
    image2 = rgb2gray(image2);
end

% ========== 2. 保存第一张图像的TIFF文件 ==========
disp('保存第一张图像的TIFF文件...');
for i = 1:numFrames
    if i == 1
        imwrite(image1, outputTiffPath1); % 写入第一帧
    else
        imwrite(image1, outputTiffPath1, 'WriteMode', 'append'); % 写入后续帧
    end
end
disp(['第一张图像已保存至: ', outputTiffPath1]);

% ========== 3. 保存第二张图像的TIFF文件 ==========
disp('保存第二张图像的TIFF文件...');
for i = 1:numFrames
    if i == 1
        imwrite(image2, outputTiffPath2); % 写入第一帧
    else
        imwrite(image2, outputTiffPath2, 'WriteMode', 'append'); % 写入后续帧
    end
end
disp(['第二张图像已保存至: ', outputTiffPath2]);

disp('两张图像的TIFF文件保存完成！');
