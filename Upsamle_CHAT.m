%% 图像上采样：提高分辨率并增强亮度
clc; clear;

% ========== 配置参数 ==========
inputImagePath1 = './LightField_Data/results/refcous_imgs/3_refocused_image_alpha_0.000.bmp'; % 输入图像路径1
inputImagePath2 = './LightField_Data/results/refcous_imgs/1_refocused_image_alpha_0.100.bmp'; % 输入图像路径2
outputImagePath1 = './LightField_Data/results/upsampled_image_alpha_0.000.bmp'; % 输出图像路径1
outputImagePath2 = './LightField_Data/results/upsampled_image_alpha_0.100.bmp'; % 输出图像路径2
scaleFactor = 3; % 上采样倍数

% ========== 1. 定义图像处理函数 ==========
function upsampleImage(inputImagePath, outputImagePath, scaleFactor)
    % 加载图像
    disp(['加载图像: ', inputImagePath]);
    originalImage = imread(inputImagePath);
    
    % 检查图像是否为灰度图像，如果不是，转换为灰度图像
    if size(originalImage, 3) == 3
        disp('输入图像为彩色图像，转换为灰度图像...');
        originalImage = rgb2gray(originalImage);
    end
    
    % 转换为双精度类型以提高插值精度
    originalImage = im2double(originalImage);
    
    % 上采样图像
    disp('上采样图像...');
    [row, col] = size(originalImage);
    [X, Y] = meshgrid(1:col, 1:row);
    [Xq, Yq] = meshgrid(linspace(1, col, col * scaleFactor), linspace(1, row, row * scaleFactor));
    upsampledImage = interp2(X, Y, originalImage, Xq, Yq, 'cubic');
    
    % 图像后处理：平滑滤波
    disp('应用平滑滤波并增强亮度...');
    upsampledImage = imgaussfilt(upsampledImage, 0.5); % 高斯平滑

    % 保存上采样后的图像
    disp(['保存上采样后的图像至: ', outputImagePath]);
    upsampledImage_uint8 = im2uint8(upsampledImage);
    imwrite(upsampledImage_uint8, outputImagePath);
    
    % 可视化原始和上采样后的图像
    figure;
    subplot(1, 2, 1);
    imshow(originalImage, []);
    title('原始图像');
    
    subplot(1, 2, 2);
    imshow(upsampledImage, []);
    title('上采样后的图像');
end

% ========== 2. 分别处理两张图像 ==========
upsampleImage(inputImagePath1, outputImagePath1, scaleFactor);
upsampleImage(inputImagePath2, outputImagePath2, scaleFactor);

disp('所有图像处理完成！');
