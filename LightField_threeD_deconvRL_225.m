%% 光场三维解卷积实验
clc; clear;

% ========== 1. 配置路径和参数 ==========
% 读取光场重排后的图像文件
TargetFile = './LightField_Data/results/shifted_images_Integer/Shifted_sample_Integer.tif'; 
View_Num = 15; 
psfPath = './Data/PSF/IdealLF_3Dpsf_M21.89_NA0.5_zmin-1.999e-05_zmax2.001e-05_zspacing1e-06.mat'; 
psfData = load(psfPath); % 加载 PSF 文件
psf = single(psfData.psf); % PSF 文件，5D维度：[rows, cols, View_Num, View_Num, znum]
[max_row, max_col, u_num, v_num, znum] = size(psf); % 提取 PSF 维度

% RL 解卷积参数
maxiter = 3; % 最大迭代次数

% ========== 2. 加载光场图像 ==========
disp('加载光场图像...');
Volume = tiffreadVolume(TargetFile); % 加载 tiff 为 3D 矩阵
[row, col, num_views] = size(Volume); % 光场尺寸
if num_views ~= View_Num * View_Num
    error('视角数量与微透镜阵列尺寸不匹配，请检查输入数据！');
end

% 上采样每个视角图像
disp('对每个视角图像进行上采样...');
Volume = imresize(Volume, 3, 'bicubic'); % 插值上采样 (3 倍)
[row, col, num_views] = size(Volume); % 更新采样后尺寸
New_Image = reshape(Volume, row, col, View_Num, View_Num); % 转换为 4D 矩阵

% ========== 3. 初始化 3D 重建 ==========
disp('初始化 3D 重建...');
Xguess = ones(row, col, znum, 'single'); % 初始估计
Xguess = Xguess ./ sum(Xguess(:)) .* sum(New_Image(:)); % 归一化

% 定义正向和反向投影函数
forwardFUN = @(Xguess, psf_uv) forwardProjectACC(Xguess, psf_uv);
backwardFUN = @(projection, psf_uv) backwardProjectACC(projection, psf_uv);

% ========== 4. 光场解卷积：视角循环 ==========
disp('开始 3D 解卷积...');
for iter = 1:maxiter
    tic; % 记录每次迭代的总时间    
    for u = 1:View_Num
        for v = 1:View_Num
            uv_tic = tic; % 记录每个视角的处理时间            
            % 提取当前视角图像
            Current_View = squeeze(New_Image(:, :, u, v)); % 2D 图像
            Current_psf = squeeze(psf(:, :, u, v, :)); % 当前视角的 PSF (3D)            
            % 正向投影
            HXguess = forwardFUN(Xguess, Current_psf); % 使用当前视角的 PSF            
            % 将 2D 的 Current_View 拓展为与 HXguess 相同尺寸的 3D
            Current_View_3D = repmat(single(Current_View), [1, 1, size(HXguess, 3)]);        
            % 计算误差
            errorEM = single(Current_View_3D) ./ (HXguess + 1e-10); % 防止除零
            errorEM(~isfinite(errorEM)) = 0; % 去除非数值点            
            % 计算反向投影
            XguessCor = backwardFUN(errorEM, Current_psf); % 使用当前视角的 PSF
            uniform_matrix = ones(size(HXguess), 'single'); % 全1矩阵，用于 Htf 计算
            Htf = backwardFUN(uniform_matrix, Current_psf);            
            % 消除噪声并更新估计
            Htf(Htf < 1e-8) = 0; % 去除小值，防止过小的更新因子
            Xguess_add = Xguess .* XguessCor ./ Htf; % 更新估计值            
            % 去除无效值并更新 Xguess
            clear Htf; clear XguessCor;
            Xguess_add(isnan(Xguess_add) | isinf(Xguess_add)) = 0; % 去除 NaN 和无穷值
            Xguess_add(Xguess_add < 0) = 0; % 去除负值            
            % 使用权重更新 Xguess（可以调节权重）
            weight = 0.2;
            Xguess = Xguess_add * weight + (1 - weight) * Xguess;            
            % 清理和修正
            clear Xguess_add;
            Xguess(isnan(Xguess)) = 0; % 再次确保无 NaN 值
            Xguess(Xguess < 1e-8) = 1e-8; % 限制最低值            
            % 打印当前视角的处理时间
            uv_toc = toc(uv_tic);
            fprintf('视角 (u=%d, v=%d) 处理时间: %.3f 秒\n', u, v, uv_toc);
        end
    end    
    % 显示每次迭代的信息
    iter_toc = toc;
    fprintf('  迭代 %d/%d 完成，用时 %.3f 秒\n', iter, maxiter, iter_toc);
end
disp('3D 解卷积完成！');


% ========== 5. 保存结果 ==========
reconPath = './LightField_Data/results/';
if ~exist(reconPath, 'dir')
    mkdir(reconPath);
end
resultFile = fullfile(reconPath, '3D_Reconstructed_Image.tif');

% 保存为tif
imwriteTFSK(uint8(real(Xguess)), resultFile);
disp(['3D 重建结果已保存至: ' resultFile]);

% ========== 6. 函数实现 ==========
% 正向投影
function projection = forwardProjectACC(Xguess, psf_uv) % psf_uv是固定uv值的3D矩阵，第3维为深度
    % 正向投影使用对应视角的 PSF
    projection = zeros(size(Xguess, 1), size(Xguess, 2), size(psf_uv,3), 'single'); % 初始化
    for z = 1:size(psf_uv,3)
        projection(:, :, z) = convn(Xguess(:, :, z), psf_uv(:, :, z), 'same');
    end
end

% 反向投影
function Backprojection = backwardProjectACC(projection, psf_uv) % psf_uv是固定uv值的3D矩阵，第3维为深度
    % 翻转 PSF
    flipped_psf = flip(psf_uv, 1);
    flipped_psf = flip(flipped_psf, 2);
    Backprojection = zeros(size(projection, 1), size(projection, 2), size(psf_uv,3), 'single'); % 初始化
    for z = 1:size(psf_uv,3)
        Backprojection(:,:,z) = convn(projection(:, :, z), flipped_psf(:,:,z),'same');
    end
end
