clc; clear;

% ========== 配置参数 ==========
inputBMP1 = './LightField_Data/video/Output2_First_Downsample.bmp'; % 输入的第一张BMP文件路径
inputBMP2 = './LightField_Data/video/refcous/refocused_image_alpha_0.450.bmp'; % 输入的第二张BMP文件路径
outputEnhancedBMP = './LightField_Data/video/output_refcous.bmp'; % 对比度强化后的BMP文件路径
weight1 = 0.4; % 第一张BMP图像的权重
weight2 = 0.6; % 第二张BMP图像的权重

% ========== 加载图像 ==========
disp('加载两张BMP图像...');
img1 = imread(inputBMP1);
img2 = imread(inputBMP2);

% 检查两张图像是否大小一致
if size(img1) ~= size(img2)
    error('两张图像的尺寸不一致，请确保图像大小相同！');
end

% 将图像转换为双精度浮点数，以便进行加权计算
img1 = im2double(img1);
img2 = im2double(img2);

% ========== 加权合成 ==========
disp('合成图像...');
combinedImage = img1 * weight1 + img2 * weight2;

% 将结果映射回 [0, 1] 范围（确保合成后图像的数值有效）
combinedImage = mat2gray(combinedImage);

% ========== 对比度强化 ==========
disp('进行对比度强化处理...');
enhancedImage = imadjust(combinedImage, stretchlim(combinedImage), []);

% 保存对比度强化后的图像
imwrite(enhancedImage, outputEnhancedBMP);
disp(['对比度强化后的图像已保存至: ', outputEnhancedBMP]);

% 显示结果
figure;
subplot(1, 3, 1);
imshow(img1, []);
title('输入图像1');

subplot(1, 3, 2);
imshow(img2, []);
title('输入图像2');

subplot(1, 3, 3);
imshow(enhancedImage, []);
title('对比度强化后的图像');
