% 原始的tiff文件路径
InputTIFF = './LightField_Data/tiffs/162_test_20X_S1_C2_B17_1.tiff';  % 包含180张图像的tiff文件
OutputFolder = './LightField_Data/results/final_realign/';

% Pixel 数量设置
Pixel_Num = 15;

% 读取tiff文件，获取180张图像
info = imfinfo(InputTIFF);  % 获取TIFF文件信息
num_images = numel(info);  % 图像数量（即180）

% 循环处理每一张图像
for idx = 1:2 %num_images
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

    % 创建重排后的tif文件，文件名可以带上当前图像的编号
    TargetFile = fullfile(OutputFolder, ['Realign_Image2_' num2str(idx) '.tif']);
    
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
