clc; clear;

% ========== 配置参数 ==========
inputTIFFPath = './LightField_Data/video/ce_1_serenet.tif'; % 输入的 TIF 文件路径
outputFolder = './output_bmp/';    % 输出 BMP 文件的保存文件夹
numFrames = 41;                   % 要导出的帧数

% 检查输出文件夹是否存在，如果不存在则创建
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% ========== 读取 TIF 文件 ==========
info = imfinfo(inputTIFFPath); % 获取 TIF 文件信息
totalFrames = numel(info);     % TIF 文件的总帧数

% 检查帧数是否超出实际帧数
if numFrames > totalFrames
    warning('指定的帧数 (%d) 超出了实际帧数 (%d)，将导出全部帧。', numFrames, totalFrames);
    numFrames = totalFrames;
end

% ========== 确定全局最大值和最小值 ==========
disp('计算全局最大值和最小值...');
globalMin = inf;
globalMax = -inf;

for idx = 1:totalFrames
    frame = imread(inputTIFFPath, idx);
    if isa(frame, 'uint16')
        frame = double(frame); % 转换为双精度浮点数
    end
    globalMin = min(globalMin, min(frame(:))); % 更新全局最小值
    globalMax = max(globalMax, max(frame(:))); % 更新全局最大值
end

disp(['全局最小值: ', num2str(globalMin)]);
disp(['全局最大值: ', num2str(globalMax)]);

% ========== 导出前 n 帧为 BMP ==========
disp('开始导出前 n 帧为 BMP 文件...');
for idx = 1:numFrames
    % 读取当前帧
    frame = imread(inputTIFFPath, idx);
    
    % 如果图像是 uint16，则将其缩放到全局范围并转换为 uint8
    if isa(frame, 'uint16')
        frame = uint8(255 * (double(frame) - globalMin) / (globalMax - globalMin)); % 归一化到全局范围并映射到 [0, 255]
    end

    % 构造输出 BMP 文件名
    outputBMPPath = fullfile(outputFolder, sprintf('frame_%03d.bmp', idx));
    
    % 保存为 BMP 文件
    imwrite(frame, outputBMPPath);
    
    fprintf('已导出第 %d 帧为 BMP 文件: %s\n', idx, outputBMPPath);
end

disp('所有指定帧已成功导出为 BMP 文件！');
