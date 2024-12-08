% 光场图像重聚焦
clc; clear;

% ========== 配置输入参数 ========== 
% 输入光场图像的 4D 矩阵路径
TargetFile = './LightField_Data/video/Shifted_Image.tif'; % 斑马鱼去噪且自适应光场处理后重聚焦
%TargetFile = './LightField_Data/video/results/Realign_NewImage_1.tif';
View_Num = 15; % 每个维度的视角数量

% ========== 加载光场图像 ========== 
Volume = tiffreadVolume(TargetFile);
New_Image = reshape(Volume, size(Volume, 1), size(Volume, 2), View_Num, View_Num);

% ========== 指定左下角1/4区域的视角索引 ========== 
% 定义左下角区域的视角索引范围
% selected_views_row = 1:7; % 列索引
% selected_views_col = 9:15;  % 行索引
selected_views_row = 1:15; % 列索引
selected_views_col = 1:15;  % 行索引

% 提取选定视角范围的图像
selected_images = New_Image(:, :, selected_views_row, selected_views_col);

% ========== 保存选定视角的图像为新的 tiff 文件 ========== 
SaveFolder = './LightField_Data/video/'; % 指定保存文件夹路径

% 创建新的 tiff 文件路径
SelectedTiffFile = fullfile(SaveFolder, 'Selected_Views.tif');

% 使用 imwrite 保存每个视角图像
for row = 1:numel(selected_views_row)
    for col = 1:numel(selected_views_col)
        % 获取当前视角图像
        current_image = squeeze(selected_images(:, :, row, col));
        
        % 将图像保存为 tiff 格式（第一个视角作为初始保存）
        if row == 1 && col == 1
            imwrite(current_image, SelectedTiffFile);
        else
            % 对后续图像追加保存
            imwrite(current_image, SelectedTiffFile, 'WriteMode', 'append');
        end
    end
end

disp(['选定视角的图像已保存到: ', SelectedTiffFile]);


% % ========== 测试重聚焦并选择最佳 alpha ========== 
% max_gradient = 0; % 初始化最大梯度
% best_alpha = 0; % 初始化最佳 alpha
% alphas = -0.5:0.01:1; % 粗略估计alpha参数
% for alpha = alphas
%     fprintf('评估重聚焦 (alpha = %.3f)...\n', alpha);
%     Refocused_Image = Refcous(selected_images, numel(selected_views_row), alpha);
%     % 计算当前图像的梯度幅值，用于评估图像清晰度
%     gradient_magnitude = sum(imgradient(Refocused_Image), 'all');
%     % 更新最佳 alpha
%     if gradient_magnitude > max_gradient
%         max_gradient = gradient_magnitude;
%         best_alpha = alpha;
%     end
% end
% fprintf('最佳 alpha 值为: %.3f\n', best_alpha);
% 
% % 最终重聚焦显示
% fprintf('使用最佳 alpha = %.3f 进行重聚焦...\n', best_alpha);
% Refocused_Image = Refcous(selected_images, numel(selected_views_row), best_alpha);
% % 显示最终结果
% figure;
% imshow(Refocused_Image, []);
% title(sprintf('Best Refocused Image (alpha = %.3f)', best_alpha));
% disp('重聚焦完成！');
% 
% %=======================================================================================================
% function Refocused_Image = Refcous(New_Image, View_Num, alpha)
%     % 光场数字重聚焦
%     % 输入参数:
%     %   - New_Image: 重排后的光场图像，4维矩阵 [row, col, View_Num, View_Num]
%     %   - View_Num: 每个小块的尺寸
%     %   - alpha: 重聚焦参数（焦平面移动因子）
%     % 输出:
%     %   - Refocused_Image: 重聚焦后的 2D 图像
% 
%     % 初始化重聚焦结果矩阵
%     [row, col, ~, ~] = size(New_Image);
%     Refocused_Image = zeros(row, col, 'single');
%     Weight_Sum = zeros(row, col, 'single'); % 用于存储权重的总和
% 
%     % 生成权重矩阵
%     center = ceil(View_Num / 2); % 中心视角
%     [U, V] = meshgrid(1:View_Num, 1:View_Num); % 视角网格
%     Distance = sqrt((U - center).^2 + (V - center).^2); % 到中心视角的距离
%     Max_Distance = max(Distance(:)); % 最大距离
%     Weights = exp(-Distance.^2 / (2 * (Max_Distance / 2)^2)); % 高斯权重（可调节）
% 
%     % 遍历每个光场视角并进行重聚焦
%     for i = 1:View_Num
%         for j = 1:View_Num
%             % 计算视角的平移量
%             delta_y = (i - center) * alpha; % 竖直方向平移
%             delta_x = (j - center) * alpha; % 水平方向平移
%             % 提取当前视角的图像
%             Sub_Image = squeeze(New_Image(:, :, i, j));
%             % 平移当前视角图像,填充0值并插值
%             Shifted_Image = imtranslate(Sub_Image, [delta_x, delta_y], 'cubic', 'FillValues', 0);
%             % 加权累加
%             Refocused_Image = Refocused_Image + single(Shifted_Image) * Weights(i, j);
%             Weight_Sum = Weight_Sum + Weights(i, j); % 累加权重
%         end
%     end
% 
%     % 对累加的重聚焦图像进行归一化（除以总权重）
%     Refocused_Image = Refocused_Image ./ Weight_Sum;
% 
%     % 保存重聚焦图像
%     SaveFolder = './LightField_Data/video/refcous'; % 指定保存的文件夹
%     if ~exist(SaveFolder, 'dir')
%         mkdir(SaveFolder); % 如果文件夹不存在，则创建
%     end
%     % 动态生成文件名，例如 'refocused_image_alpha_0.00018.bmp'
%     FileName = sprintf('refocused_image_alpha_%.3f.bmp', alpha);
%     FullPath = fullfile(SaveFolder, FileName); % 合成完整路径
%     % 保存图像
%     imwrite(uint8(255 * mat2gray(Refocused_Image)), FullPath);
%     disp(['重聚焦图像已保存到: ', FullPath]);
% 
% end
% 
% 
