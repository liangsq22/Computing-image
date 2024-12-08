ImageFile = "./LightField_Data/imgs/狗平滑肌切片1.bmp";
Pixel_Num = 15;

% 寻找重排中心
Center_X = GetClose(354, 512, Pixel_Num); 
Center_Y = GetClose(563, 640, Pixel_Num); 
Left_Side = Center_X-33*Pixel_Num;
Right_Side = Center_X+33*Pixel_Num-1;
Bottom_Side = Center_Y-33*Pixel_Num;
Top_Side = Center_Y+33*Pixel_Num-1;

Raw_Image=imread(ImageFile);

Resize_Scale = 0.996; % 缩放比例
% 调参测试记录：0.996最佳，0.999-0.99都有纯黑视角，放大（1以上）则存在阴影遮挡

Resize_Image = imresize(Raw_Image, Resize_Scale);
OutputFile_1 = fullfile('./LightField_Data/results', 'Resize_Image.bmp');
imwrite(Resize_Image, OutputFile_1);

Cut_Image=Resize_Image(Left_Side : Right_Side, Bottom_Side : Top_Side);
OutputFile_2 = fullfile('./LightField_Data/results', 'Cut_Image.bmp');
imwrite(Cut_Image, OutputFile_2);

New_Image=uint8(realign(Cut_Image, Pixel_Num));

% 创建重排后的tif，共15*15=225张
TargetFile = './LightField_Data/results/Realign_Image.tif';
for i=1:Pixel_Num
    for j=1:Pixel_Num
        if i==1 && j==1
            imwrite(New_Image(:,:,i,j),TargetFile);
        else
            imwrite(New_Image(:,:,i,j),TargetFile,'Writemode','append');
        end
    end
end

% =====================================================================================================================
% 函数realign实现
function New_Image = realign(Cut_Image, Pixel_Num)
    num_blocks_row = size(Cut_Image, 1) / Pixel_Num;
    num_blocks_col = size(Cut_Image, 2) / Pixel_Num;
    Temp_Image=ones(Pixel_Num,Pixel_Num,num_blocks_row,num_blocks_col); 
    % 临时数组生成
    for i=1:Pixel_Num
        for j=1:Pixel_Num
            for m=1:size(Cut_Image,1)/Pixel_Num
                for n=1:size(Cut_Image,2)/Pixel_Num
                    Temp_Image(i,j,m,n)=Cut_Image((m-1)*Pixel_Num+i,(n-1)*Pixel_Num+j);
                end
            end
        end
    end
    % 写入新图像集
    New_Image=ones(size(Cut_Image,1)/Pixel_Num,size(Cut_Image,2)/Pixel_Num,Pixel_Num,Pixel_Num); 
    for i=1:Pixel_Num
        for j=1:Pixel_Num
            New_Image(:,:,i,j) = Temp_Image(i,j,:,:);
        end
    end
end

% 函数GetClose实现：找到距中心点较近的圆心坐标
function Answer = GetClose(current,goal,num)
    Answer = goal + mod(current, num) - mod(goal,num);
    if (Answer < goal)
        Answer = Answer + num;
    end
end
