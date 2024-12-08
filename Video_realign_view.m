% 原始的tiff文件路径
InputTIFF = './LightField_Data/video/Video_20241209220554285.avi';  
OutputFolder = './LightField_Data/video/results/';

% Pixel 数量设置
Pixel_Num = 15;

% 读取tiff文件，获取180张图像
info = VideoReader(InputTIFF);  
num_images = numel(info);  

% 循环处理每一张图像
for idx = 1:2 %num_images
    % 读取当前的图像
    Raw_Image = read(info, idx);
    
    % 寻找重排中心
    Center_X = GetClose(362, 512, Pixel_Num); 
    Center_Y = GetClose(571, 640, Pixel_Num); 
    Left_Side = Center_X-33*Pixel_Num;
    Right_Side = Center_X+33*Pixel_Num-1;
    Bottom_Side = Center_Y-33*Pixel_Num;
    Top_Side = Center_Y+33*Pixel_Num-1;

    % 图像缩放
    Resize_Scale = 0.9965; % 缩放比例
    Resize_Image = imresize(Raw_Image, Resize_Scale);
    
    % 裁剪图像
    Cut_Image = Resize_Image(Left_Side : Right_Side, Bottom_Side : Top_Side);

    % 图像重排
    New_Image = uint16(realign(Cut_Image, Pixel_Num));

    % 在每一帧上应用高斯平滑滤波
    sigma = 1;  % 设置高斯滤波的标准差，调整以适应实际需求
    for i = 1:Pixel_Num
        for j = 1:Pixel_Num
            % 对每一帧应用高斯平滑滤波
            New_Image(:,:,i,j) = imgaussfilt(New_Image(:,:,i,j), sigma);
        end
    end
    
    % 创建重排后的tif文件，文件名可以带上当前图像的编号
    TargetFile = fullfile(OutputFolder, ['Realign_Image_' num2str(idx) '.tif']);
    
    % 将重排后的图像写入 TIFF 文件
    for i = 1:Pixel_Num
        for j = 1:Pixel_Num
            if i == 1 && j == 1
                imwrite(New_Image(:,:,i,j), TargetFile);
            else
                imwrite(New_Image(:,:,i,j), TargetFile, 'WriteMode', 'append');
            end
        end
    end
end

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
