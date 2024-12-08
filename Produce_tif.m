% 获取当前工作目录
currentDir = pwd;
disp(['当前工作目录为: ', currentDir]);

% 输出的 TIFF 文件名，直接使用文件名（不带路径）
outputFile = 'stack.tif';

% 假设你有 11 个 BMP 文件，从 slice_1.bmp 到 slice_11.bmp
num_slices = 11;

% 循环读取 BMP 文件、处理图像并写入多页 TIFF 文件
for k = 1:num_slices
   bmpFile = sprintf('slice_%d.bmp', k);  % 构建 BMP 文件名，从 slice_1.bmp 到 slice_11.bmp
   img = imread(bmpFile);  % 读取 BMP 文件
   
   % 转换为灰度图像，如果图像是彩色的
   if size(img, 3) == 3
       img = rgb2gray(img);
   end
   
   % 转换为双精度格式并归一化到 [0, 1] 范围
   img = im2double(img);
   
   % 将处理后的图像写入 TIFF 文件
   if k == 1
       imwrite(img, outputFile, 'tif', 'WriteMode', 'overwrite');  % 第一次写入
   else
       imwrite(img, outputFile, 'tif', 'WriteMode', 'append');  % 后续页追加
   end
end

disp(['文件已保存为: ', fullfile(currentDir, outputFile)]);
