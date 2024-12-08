clc; clear;

% ========== 配置参数 ========== 
inputTIFFPath = './LightField_Data/video/results/Viedo_Realign_View_200.tif'; % 输入的tiff文件路径
outputTIFFPath = './LightField_Data/video/results/New3_Video_Realign_View200.tif'; % 输出的tiff文件路径
scaleFactor = 7; % 上采样倍数

% ========== 1. 定义图像处理函数 ========== 
function upsampleTIFF(inputTIFFPath, outputTIFFPath, scaleFactor)
    % 获取输入tiff文件的信息
    disp(['加载 tiff 文件: ', inputTIFFPath]);
    info = imfinfo(inputTIFFPath);
    numFrames = numel(info); % 获取tiff中的帧数
    
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

        originalImage = imgaussfilt(originalImage, 0.7); % 高斯平滑

        % 上采样图像，使用imresize并选择bicubic插值
        disp('上采样图像...');
        upsampledImage = imresize(originalImage, scaleFactor, 'cubic');
        
        % 保持为16位类型
        upsampledImage = im2uint16(upsampledImage);

        % 将每一帧保存到临时列表中
        allImages{end + 1} = upsampledImage; % 将每帧图像保存到数组中
    end
    
    % 将所有帧写入输出的tiff文件
    disp('开始保存所有上采样后的帧...');
    for i = 1:length(allImages)
        disp(['正在处理第 ', num2str(i), ' 帧...']);
        if i == 1
            imwrite(allImages{i}, outputTIFFPath, 'WriteMode', 'overwrite');
        else
            imwrite(allImages{i}, outputTIFFPath, 'WriteMode', 'append');
        end
    end
    
    disp(['所有帧处理完成并保存为: ', outputTIFFPath]);
end

% ========== 2. 对tiff文件进行上采样处理 ========== 
upsampleTIFF(inputTIFFPath, outputTIFFPath, scaleFactor);

disp('所有图像处理完成！');
