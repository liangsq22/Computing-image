clc; clear;

% ========== 配置参数 ==========
inputVideoPath = './LightField_Data/video/Video_20241209220554285.avi'; % 输入视频路径
outputFolder = './output_bmp/';       % 输出 BMP 文件的保存文件夹
numFrames = 50;                       % 要导出的帧数

% 检查输出文件夹是否存在，如果不存在则创建
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% ========== 读取视频 ==========
disp('加载视频...');
videoObj = VideoReader(inputVideoPath); % 创建 VideoReader 对象
totalFrames = floor(videoObj.Duration * videoObj.FrameRate); % 计算总帧数

% 检查帧数是否超出实际帧数
if numFrames > totalFrames
    warning('指定的帧数 (%d) 超出了实际帧数 (%d)，将导出全部帧。', numFrames, totalFrames);
    numFrames = totalFrames;
end

% ========== 导出前 n 帧为 BMP ==========
disp('开始导出前 n 帧为 BMP 文件...');
for idx = 1:numFrames
    % 读取当前帧
    frame = read(videoObj, idx);
    
    % 检查是否为彩色图像，并转换为灰度图像（可选）
    if size(frame, 3) == 3 % 如果是 RGB 图像
        frameGray = rgb2gray(frame); % 转换为灰度图像
    else
        frameGray = frame; % 如果是灰度图像，直接使用
    end

    % 构造输出 BMP 文件名
    outputBMPPath = fullfile(outputFolder, sprintf('frame_%03d.bmp', idx));
    
    % 保存为 BMP 文件
    imwrite(frameGray, outputBMPPath);
    
    fprintf('已导出第 %d 帧为 BMP 文件: %s\n', idx, outputBMPPath);
end

disp('所有指定帧已成功导出为 BMP 文件！');
