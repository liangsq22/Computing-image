%% 裁剪视角15*15的psf为9*9
% ========== 配置路径和参数 ==========
psfPath = './Data/PSF/IdealLF_3Dpsf_M21.89_NA0.5_zmin-1.999e-05_zmax2.001e-05_zspacing1e-06.mat';
outputPsfPath = './Data/PSF/Reduced_3Dpsf_9x9.mat'; % 保存缩减后的 PSF 文件
View_Num_Original = 15; % 原始视角数量 (15×15)
View_Num_Reduced = 9; % 缩减后的视角数量 (9×9)
Center_Original = ceil(View_Num_Original / 2); % 原始中心视角
Center_Reduced = ceil(View_Num_Reduced / 2); % 缩减后的中心视角
Half_Reduced = floor(View_Num_Reduced / 2); % 半径范围

% 加载 PSF 数据
psfData = load(psfPath); % 加载原始 PSF 文件
psf = single(psfData.psf); % PSF 文件，5D维度：[rows, cols, View_Num, View_Num, znum]
[max_row, max_col, u_num, v_num, znum] = size(psf); % 提取 PSF 维度

% 检查原始视角数量是否匹配
if u_num ~= View_Num_Original || v_num ~= View_Num_Original
    error('原始 PSF 文件的视角数量与指定的 View_Num_Original 不匹配！');
end

% ========== 提取 9×9 中心区域的 PSF ==========
disp('缩减 PSF 数据为 9×9 中心视角...');
reduced_psf = psf(:, :, ...
    Center_Original-Half_Reduced:Center_Original+Half_Reduced, ...
    Center_Original-Half_Reduced:Center_Original+Half_Reduced, ...
    :); % 提取中心 9×9 区域的 PSF
[max_row_reduced, max_col_reduced, u_num_reduced, v_num_reduced, znum_reduced] = size(reduced_psf);

% 检查缩减后的维度是否正确
if u_num_reduced ~= View_Num_Reduced || v_num_reduced ~= View_Num_Reduced
    error('缩减后的 PSF 视角数量不正确，请检查代码逻辑！');
end

% ========== 保存缩减后的 PSF ==========
disp('保存缩减后的 PSF 数据...');
save(outputPsfPath, 'reduced_psf');
disp(['缩减后的 PSF 已保存至: ', outputPsfPath]);

% 打印结果维度信息
fprintf('原始 PSF 视角数量: [%d x %d]\n', u_num, v_num);
fprintf('缩减后 PSF 视角数量: [%d x %d]\n', u_num_reduced, v_num_reduced);
