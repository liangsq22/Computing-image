clc;
clear;

% 配置参数
inputVideoPath = './LightField_Data/video/Video_20241209220554285.avi'; % 输入视频路径
outputTIFFPath = './LightField_Data/video/results/'; % 输出tiff文件路径
Pixel_Num = 15;  % Pixel 数量设置
maxFrames = 500; % 处理的最大帧数

% 读取视频文件
videoObj = VideoReader(inputVideoPath);
frameRate = videoObj.FrameRate; % 获取帧率
num_frames = floor(videoObj.Duration * frameRate); % 计算视频帧数1166
num_frames = min(num_frames, maxFrames); % 取前500帧约半分钟

% 创建一个空的cell数组用于存储每个视角的图像
New_Images = cell(Pixel_Num, Pixel_Num);

% 创建一个新的tiff文件用于保存重排后的图像
disp('开始输出重排后的TIFF文件...');
for idx = 1:num_frames
    % 读取当前帧图像
    currentFrame = read(videoObj, idx);
    disp(['正在处理第 ', num2str(idx), ' 帧（', num2str(idx), '/', num2str(num_frames), '）']);
    
    % 寻找重排中心
    Center_X = GetClose(362, 512, Pixel_Num); 
    Center_Y = GetClose(571, 640, Pixel_Num); 
    Left_Side = Center_X-33*Pixel_Num;
    Right_Side = Center_X+33*Pixel_Num-1;
    Bottom_Side = Center_Y-33*Pixel_Num;
    Top_Side = Center_Y+33*Pixel_Num-1;

    % 图像缩放
    Resize_Scale = 0.9965; % 缩放比例
    Resize_Image = imresize(currentFrame, Resize_Scale);
    
    % 裁剪图像
    Cut_Image = Resize_Image(Left_Side : Right_Side, Bottom_Side : Top_Side, :);

    % 图像重排
    New_Image = uint16(realign(Cut_Image, Pixel_Num));
    
    % 存储每个视角的图像
    for i = 1:Pixel_Num
        for j = 1:Pixel_Num
            New_Images{i,j}(:,: ,idx) = New_Image(:,:,i,j);
        end
    end
end

% 输出时序的tiff文件，按视角拼接
for i = 1:Pixel_Num
    for j = 1:Pixel_Num
        disp(['正在写入视角第 ', num2str(i), '行', num2str(j), '列']);
        % 为每个视角创建一个单独的时序tiff文件
        TargetFile = fullfile(outputTIFFPath, ['Viedo_Realign_View_' num2str((i-1)*Pixel_Num + j) '.tif']);
        
        % 将所有时序帧写入该视角的tiff文件
        imwrite(New_Images{i,j}(:,:,1), TargetFile);  % 第一个时序帧
        for k = 2:num_frames
            imwrite(New_Images{i,j}(:,:,k), TargetFile, 'WriteMode', 'append');  % 后续时序帧
        end
    end
end

disp('所有图像处理完成，输出为tiff文件。');

% ================================================================================================================
% 函数realign实现
function New_Image = realign(Cut_Image, Pixel_Num)
    num_blocks_row = size(Cut_Image, 1) / Pixel_Num;
    num_blocks_col = size(Cut_Image, 2) / Pixel_Num;
    Temp_Image = ones(Pixel_Num, Pixel_Num, num_blocks_row, num_blocks_col); 
    % 临时数组生成
    for i = 1:Pixel_Num
        for j = 1:Pixel_Num
            for m = 1:size(Cut_Image,1)/Pixel_Num
                for n = 1:size(Cut_Image,2)/Pixel_Num
                    Temp_Image(i,j,m,n) = Cut_Image((m-1)*Pixel_Num+i, (n-1)*Pixel_Num+j);
                end
            end
        end
    end
    
    % 写入新图像集
    New_Image = ones(size(Cut_Image,1)/Pixel_Num, size(Cut_Image,2)/Pixel_Num, Pixel_Num, Pixel_Num); 
    for i = 1:Pixel_Num
        for j = 1:Pixel_Num
            New_Image(:,:,i,j) = Temp_Image(i,j,:,:);
        end
    end
end

% ================================================================================================================
% 函数GetClose实现：找到距中心点较近的圆心坐标
function Answer = GetClose(current, goal, num)
    Answer = goal + mod(current, num) - mod(goal, num);
    if (Answer < goal)
        Answer = Answer + num;
    end
end

