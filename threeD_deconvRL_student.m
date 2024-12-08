%% wide field 3D RL deconvolution 
clear; close all;
imgName = 'stack';
imgPath = strcat('./Data/imgs/', imgName, '.tif');
WF = im2double(imread(imgPath));  % 将 WF 转为 double 类型，确保数据一致性

maxiter = 5;
aaa = load('./Data/PSF/Ideal_3Dpsf_M21.89_NA0.5_zmin-9.99e-06_zmax1.001e-05_zspacing2e-06.mat');
psf = single(aaa.psf);  % 将 psf 保持为 single 类型

% Initialization
WF=imresize(WF,[size(WF,1)*3,size(WF,2)*3],'bicubic'); % 插值使像素扩大到3倍
Xguess=ones(size(WF,1),size(WF,2),size(psf,3));
Xguess=Xguess./sum(Xguess(:)).*sum(WF(:));
% 定义forwardFUN，backwardFUN
forwardFUN = @(Xguess) forwardProjectACC( psf, Xguess );
backwardFUN = @(projection) backwardProjectACC(psf, projection );
uniform_matrix = single(ones(size(WF, 1), size(WF, 2), size(psf, 3)));  % 定义单位矩阵


% RL deconvolution
for iter = 1:maxiter
    tic;
    HXguess = forwardFUN(Xguess);  
    % 计算误差
    errorEM = double(WF) ./ (HXguess);  
    errorEM(~isfinite(errorEM)) = 0;
    
    % 计算反向投影
    XguessCor = backwardFUN(errorEM); 
    Htf = backwardFUN(uniform_matrix);
    % 消除噪声并更新估计
    Htf(Htf < 1e-4) = 0;  
    Xguess_add = Xguess .* XguessCor ./ Htf;

    % 去除无效值并更新 Xguess
    clear Htf;clear XguessCor;
    Xguess_add(isnan(Xguess_add) | isinf(Xguess_add)) = 0;
    Xguess_add(Xguess_add < 0) = 0;
    % 更新权重0.2
    Xguess = Xguess_add * 0.2 + (1 - 0.2) * Xguess;
    % 清理和修正
    clear Xguess_add;
    Xguess(find(isnan(Xguess))) = 0;
    Xguess(Xguess < 1e-4) = 1e-4;
    
    % 迭代时间显示
    ttime = toc;
    disp(['  iter ' num2str(iter) ' | ' num2str(maxiter) ', took ' num2str(ttime) ' secs']);    
end

% 保存结果
if ~exist('./Data/recon', 'dir')
    mkdir('./Data/recon');
end
imwriteTFSK(single(real(Xguess)), ['./Data/recon/deconvImage.tiff']);
disp('3D解卷积结束')


% =======================================================================================================================
function projection = forwardProjectACC(psf, Xguess)
    % 检查并确保 Xguess 和 psf 的第三维度一致
    if size(Xguess, 3) ~= size(psf, 3)
        error('Xguess and psf must have the same number of layers in the third dimension.');
    end
    % 初始化 projection，确保它是三维矩阵
    projection = zeros(size(Xguess, 1), size(Xguess, 2), size(psf,3));
    % 按第三维度逐层卷积
    for z = 1:size(psf, 3)
        projection(:,:,z) = convn(double(Xguess(:,:,z)), double(psf(:,:,z)), 'same');
    end
end


function Backprojection = backwardProjectACC(psf, projection)
    % 翻转psf
    flipped_psf = flip(psf, 1);
    flipped_psf = flip(flipped_psf, 2);
    Backprojection = zeros(size(projection, 1), size(projection, 2), size(projection, 3));
    % 逐层卷积
    for z = 1:size(flipped_psf, 3)
        Backprojection(:,:,z) = convn(double(projection(:,:,z)), double(flipped_psf(:,:,z)), 'same');
    end
end
