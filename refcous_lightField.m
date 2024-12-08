% 光场图像重聚焦
clc; clear;

% ========== 配置输入参数 ==========
% 输入光场图像的 4D 矩阵路径
%TargetFile = './LightField_Data/results/Realign_Image.tif'; % 重排后的多页 TIFF 文件路径
TargetFile = './LightField_Data/results/shifted_images_Integer/Shifted_sample_Integer_1.tif'; % 实验四自适应光场处理后重聚焦
View_Num = 15; % 每个维度的视角数量

% ========== 加载光场图像 ==========
Volume = tiffreadVolume(TargetFile);
New_Image = reshape(Volume, size(Volume, 1), size(Volume, 2), View_Num, View_Num);

% % ========== 测试重聚焦并选择最佳 alpha ==========
% max_gradient = 0; % 初始化最大梯度
% best_alpha = 0; % 初始化最佳 alpha
% alphas = -0.5:0.02:0.5; %粗略估计alpha参数
% for alpha = alphas
%     fprintf('评估重聚焦 (alpha = %.3f)...\n', alpha);
%     Refocused_Image = Refcous(New_Image, View_Num, alpha);
%     % 计算当前图像的梯度幅值，用于评估图像清晰度
%     gradient_magnitude = sum(imgradient(Refocused_Image), 'all');
%     % 更新最佳 alpha
%     if gradient_magnitude > max_gradient
%         max_gradient = gradient_magnitude;
%         best_alpha = alpha;
%     end
% end
% fprintf('粗略最佳 alpha 值为: %.3f\n', best_alpha);

% ========== 使用更精细 alpha 值进行重聚焦 ==========
max_gradient = 0; % 初始化最大梯度
best_alpha = 0; % 初始化最佳 alpha
%alphas = -0.02:0.001:0.02; % 更精确的 alpha 参数范围1
alphas = 0.16:0.001:0.2; % 更精确的 alpha 参数范围2
for alpha = alphas
    fprintf('评估重聚焦 (alpha = %.3f)...\n', alpha);
    Refocused_Image = Refcous(New_Image, View_Num, alpha);
    % 计算当前图像的梯度幅值，用于评估图像清晰度
    gradient_magnitude = sum(imgradient(Refocused_Image), 'all');
    % 更新最佳 alpha
    if gradient_magnitude > max_gradient
        max_gradient = gradient_magnitude;
        best_alpha = alpha;
    end
end
fprintf('最佳 alpha 值为: %.3f\n', best_alpha);
%最终重聚焦显示
fprintf('使用最佳 alpha = %.3f 进行重聚焦...\n', best_alpha);
Refocused_Image = Refcous(New_Image, View_Num, best_alpha);
% 显示最终结果
figure;
imshow(Refocused_Image, []);
title(sprintf('Best Refocused Image (alpha = %.3f)', best_alpha));
disp('重聚焦完成！');


%=======================================================================================================
function Refocused_Image = Refcous(New_Image, View_Num, alpha)
    % 光场数字重聚焦
    % 输入参数:
    %   - New_Image: 重排后的光场图像，4维矩阵 [row, col, View_Num, View_Num]
    %   - View_Num: 每个小块的尺寸
    %   - alpha: 重聚焦参数（焦平面移动因子）
    % 输出:
    %   - Refocused_Image: 重聚焦后的 2D 图像
    
    % 初始化重聚焦结果矩阵
    [row, col, ~, ~] = size(New_Image);
    Refocused_Image = zeros(row, col, 'single');
    
    % 遍历每个光场视角并进行重聚焦
    for i = 1:View_Num
        for j = 1:View_Num
            % 计算视角的平移量
            delta_y = (i - ceil(View_Num / 2)) * alpha; % 竖直方向平移
            delta_x = (j - ceil(View_Num / 2)) * alpha; % 水平方向平移
            % 提取当前视角的图像
            Sub_Image = squeeze(New_Image(:, :, i, j));
            % 平移当前视角图像,填充0值并插值
            Shifted_Image = imtranslate(Sub_Image, [delta_x, delta_y], 'cubic', 'FillValues', 0);
            % 累加到重聚焦结果中
            Refocused_Image = Refocused_Image + single(Shifted_Image);
        end
    end
    
    % 对累加的重聚焦图像进行归一化
    Refocused_Image = Refocused_Image / (View_Num * View_Num);
    
    % 保存重聚焦图像
    SaveFolder = './LightField_Data/results/refcous_imgs'; % 指定保存的文件夹
    if ~exist(SaveFolder, 'dir')
        mkdir(SaveFolder); % 如果文件夹不存在，则创建
    end
    % 动态生成文件名，例如 'refocused_image_alpha_0.00018.bmp'
    %FileName = sprintf('3_refocused_image_alpha_%.3f.bmp', alpha); % 根据 alpha 和切片类型生成文件名
    FileName = sprintf('1_refocused_image_alpha_%.3f.bmp', alpha);
    FullPath = fullfile(SaveFolder, FileName); % 合成完整路径
    % 保存图像
    imwrite(uint8(255 * mat2gray(Refocused_Image)), FullPath);
    disp(['重聚焦图像已保存到: ', FullPath]);

end
