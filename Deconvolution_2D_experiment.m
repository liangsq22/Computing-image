% Step 1: 加载图像
sample_img = imread('./Data/imgs/slice_6.bmp');  % 请确保 sample_image.jpg 文件在当前工作目录

% 如果是彩色图像，将其转换为灰度图
disp(size(sample_img, 3));
if size(sample_img, 3) == 3
    sample_img = rgb2gray(sample_img);
end

% 转换为双精度格式，确保图像值在 [0, 1] 范围内
sample_img = im2double(sample_img);

% 解卷积实验代码

% Step 2: 加载 PSF
load('./Data/PSF/Ideal_psf_atFocus_M21.89_NA0.5_zmin-9.99e-06_zmax1.001e-05_zspacing2e-06.mat');  % 加载新生成的 PSF 文件
if exist('psf_0', 'var')
    psf = psf_0;
else
    error('PSF 文件中找不到变量 psf_0');
end

% Step 3: 初始化解卷积参数
maxiter = 10;  % 最大迭代次数
deblurred_img = ones(size(sample_img));  % 初始估计图像
psf_conjugate = psf(end:-1:1, end:-1:1);  % 将 PSF 翻转，供反向传播使用

% Step 4: 自定义解卷积算法（迭代）
for iter = 1:maxiter
    % 正向传播：使用 PSF 卷积
    convolved_img = conv2(deblurred_img, psf, 'same');

    % 计算误差相对值
    errorRelative = norm(sample_img - convolved_img) / norm(sample_img);
    fprintf('Iteration %d: Relative Error = %.4f\n', iter, errorRelative);
    
    % 计算误差：使用反向传播的卷积
    errorF = sample_img ./ (convolved_img + eps);  % 避免除零
    deblurred_img = deblurred_img .* conv2(errorF, psf_conjugate, 'same');
    
    % 防止数值异常
    deblurred_img(isnan(deblurred_img)) = 0;
    deblurred_img(deblurred_img < 0) = 0;
end

% Step 5: 使用 MATLAB 内置的 deconvlucy 进行解卷积
deconvlucy_result = deconvlucy(sample_img, psf, maxiter);

% Step 6: 显示结果对比
figure;
subplot(2, 2, 1); imshow(sample_img, []); title('Original Image');
subplot(2, 2, 3); imshow(deblurred_img, []); title('Custom Deconvolution Result');
subplot(2, 2, 4); imshow(deconvlucy_result, []); title('MATLAB deconvlucy Result');
