% 原始的tiff文件路径
InputTIFF = './LightField_Data/tiffs/162_test_20X_S1_C2_B17_0.tiff';  % 包含180张图像的tiff文件
OutputFolder = './LightField_Data/results/final_realign/';

% Pixel 数量设置
Pixel_Num = 15;

% 读取tiff文件，获取180张图像
info = imfinfo(InputTIFF);  % 获取TIFF文件信息
num_images = numel(info);  % 图像数量（即180）

% 创建一个空的cell数组用于存储每个视角的图像
New_Images = cell(Pixel_Num, Pixel_Num);

% 循环处理每一张图像
for idx = 1:num_images
    % 显示当前正在处理的图像
    fprintf('正在处理第 %d 张图像（%d/%d）\n', idx, idx, num_images);    
    % 记录当前图像的处理时间
    tic;
    
    % 读取当前的图像
    Raw_Image = imread(InputTIFF, idx);
    
    % 寻找重排中心
    Center_X = GetClose(352, 1208, Pixel_Num); 
    Center_Y = GetClose(546, 1208, Pixel_Num); 
    Left_Side = Center_X - 60 * Pixel_Num;
    Right_Side = Center_X + 60 * Pixel_Num - 1;
    Bottom_Side = Center_Y - 60 * Pixel_Num;
    Top_Side = Center_Y + 60 * Pixel_Num - 1;

    % 图像缩放
    Resize_Scale = 1; % 缩放比例
    Resize_Image = imresize(Raw_Image, Resize_Scale);
    
    % 裁剪图像
    Cut_Image = Resize_Image(Left_Side : Right_Side, Bottom_Side : Top_Side);

    % 图像重排
    New_Image = uint16(realign(Cut_Image, Pixel_Num));
    
    % 存储每个视角的图像
    for i = 1:Pixel_Num
        for j = 1:Pixel_Num
            New_Images{i,j}(:,: ,idx) = New_Image(:,:,i,j);
        end
    end
    
    % 输出当前图像的处理时间
    elapsedTime = toc;
    fprintf('第 %d 张图像处理完毕，耗时 %.4f 秒\n', idx, elapsedTime);
end

% 输出时序的tiff文件，按视角拼接
disp('开始输出时序TIFF文件...');
for i = 1:Pixel_Num
    for j = 1:Pixel_Num
        % 为每个视角创建一个单独的时序tiff文件
        TargetFile = fullfile(OutputFolder, ['Realign_View_' num2str((i-1)*Pixel_Num + j) '.tif']);
        
        % 将所有时序帧写入该视角的tiff文件
        imwrite(New_Images{i,j}(:,:,1), TargetFile);  % 第一个时序帧
        for k = 2:num_images
            imwrite(New_Images{i,j}(:,:,k), TargetFile, 'WriteMode', 'append');  % 后续时序帧
        end
        
        % 每处理一个视角输出一次
        fprintf('已完成视角 %d（%d/%d）\n', (i-1)*Pixel_Num + j, (i-1)*Pixel_Num + j, Pixel_Num^2);
    end
end

disp('所有图像处理完成。');

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
