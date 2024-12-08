%% 图像上采样：提高分辨率（保持16位数据），并将每3个重复的180帧合并成540帧
clc; clear;

% ========== 配置参数 ========== 
inputTIFFPath = './LightField_Data/results/final_realign/Realign_View_1.tif'; % 输入的tiff文件路径
outputTIFFPath = './LightField_Data/results/final_realign/New_Realign_View_1.tif'; % 输出的tiff文件路径
scaleFactor = 4; % 上采样倍数

% ========== 1. 定义图像处理函数 ========== 
function upsampleTIFF(inputTIFFPath, outputTIFFPath, scaleFactor)
    % 获取输入tiff文件的信息
    disp(['加载 tiff 文件: ', inputTIFFPath]);
    info = imfinfo(inputTIFFPath);
    numFrames = numel(info); % 获取tiff中的帧数
    
    % 确保tiff帧数为180帧
    if numFrames ~= 180
        error('输入的tiff文件必须包含180帧');
    end
    
    % 创建一个新的tiff文件用于保存处理结果
    disp(['保存上采样后的 tiff 文件至: ', outputTIFFPath]);

    allImages = {}; % 用于保存所有上采样后的图像

    for idx = 1:numFrames
        % 读取当前帧图像
        disp(['正在处理第 ', num2str(idx), ' 帧...']);
        originalImage = imread(inputTIFFPath, idx);

        % 确保图像为16位类型，不做数据类型转换
        if ~isa(originalImage, 'uint16')
            error('图像不是16位类型，请确认输入图像类型为 uint16');
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
        disp('应用平滑滤波...');
        upsampledImage = imgaussfilt(upsampledImage, 0.5); % 高斯平滑
        
        % 保持为16位类型
        upsampledImage = im2uint16(upsampledImage);

        % 将每一帧保存到临时列表中
        allImages{end + 1} = upsampledImage; % 将每帧图像保存到数组中
    end
    
    % 生成最终的540帧（重复180帧三次）
    disp('将每180帧重复三次，生成540帧...');
    newFrames = [allImages, allImages, allImages]; % 重复180帧三次
    
    % 将所有帧写入输出的tiff文件
    for i = 1:length(newFrames)
        disp(['正在处理第 ', num2str(i), ' 帧...']);
        if i == 1
            imwrite(newFrames{i}, outputTIFFPath, 'WriteMode', 'overwrite');
        else
            imwrite(newFrames{i}, outputTIFFPath, 'WriteMode', 'append');
        end
    end
    
    disp(['所有帧处理完成并保存为: ', outputTIFFPath]);
end

% ========== 2. 对tiff文件进行上采样处理 ========== 
upsampleTIFF(inputTIFFPath, outputTIFFPath, scaleFactor);

disp('所有图像处理完成！');
