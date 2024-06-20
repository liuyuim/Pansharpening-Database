%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%根据正射校后的数据数据集，自动生成融合数据的代码。
%为解决方法Demo_CreateFusionPairs_2.m对影像自动配准速度慢的问题，尝试根据地理坐标自动匹配全色和多光谱数据，然后取出对应地理范围一致的块
%
% % % % % % % % % % % % %
%
% Version: 1
%
% % % % % % % % % % % % %
%
% Copyright (C) 2022
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear
close all
addpath(genpath('../Toolbox\'));
%% 获得所有原始数据对所在文件夹
% 默认数据存在MS-Pan_Orth文件夹下，全色和多光谱图像分别命名为Pan和MS，格式为TIF
%全部原始数据所在路径
%ImgPaths = 'E:\Code-Papers\FusionBenchmark\Data\';
ImgPaths = '.\Benchmark_Data\GF1\1';

%标识所有路径的字符串，以；分开
AllDirs = genpath((ImgPaths));
length_p = size(AllDirs,2);%字符的长度
PathLen = length(ImgPaths);%路径的长度

%寻找分隔符“；，找到分隔符且分割符前字符是“MS-Pan_Orth”就将路径记录下来
pathList = {}; %
temp= [];
for  i = 1:length_p %
    if AllDirs(i) ~=';'
        temp = [temp AllDirs(i)];
    elseif isequal(AllDirs(i-11:i-1),'MS-Pan_Orth')
        temp = [ temp '\'];
        pathList = [pathList;temp];
        temp = [];
    else
        temp = [];
    end
end
%% 读取每对影像
PatchSize = [1024, 1024]; %设定每块图像的大小
NumImgs = size(pathList,1);
for  i = 1:NumImgs
    %空文件跳过
    if ~exist([pathList{i}, 'MS.tif'], 'file')
        continue
    end
    
    %获取图像传感器基本信息
    SensorName = pathList{i}(PathLen+1:end-15);
    
    %读取多光谱影像
    [MS,R_MS] = readgeoraster([pathList{i}, 'MS.tif']);
%     info_MS = geotiffinfo([pathList{i}, 'MS.tif']);
    [height_MS, width_MS, dim_MS] = size(MS);
    %     figure, mapshow(MS(:,:,4:-1:2), R_MS);
    
    %读取全色影像
    [Pan, R_Pan] = readgeoraster([pathList{i}, 'Pan.tif']);
%     info_Pan = geotiffinfo([pathList{i}, 'Pan.tif']);
    %     figure,mapshow(Pan, R_Pan);
    
    %根据影像分辨率的差异，确定放缩倍数（一般为4倍）
    Scale = round ((R_MS.CellExtentInWorldX/R_Pan.CellExtentInWorldX + R_MS.CellExtentInWorldY/R_Pan.CellExtentInWorldY)/2);
    
    %将全色影像调整为多光谱影像大小的Scale倍,同时更新Referencing Object
    Pan = imresize(Pan, [height_MS, width_MS]*Scale, 'bicubic');
    R_Pan.RasterSize = [height_MS, width_MS]*Scale;%The resized image has the same limits as the original, just a smaller size, so copy the referencing object and reset its RasterSize property.
    %% pad image to have dimensions as multiples of patchSize（填充图像以使其尺寸为 patchSize 的整倍数）
    
    %全色影像应为PatchSize倍数，
    [height_Pan, width_Pan] = size(Pan);
    padSize(1) = PatchSize(1) - mod(height_Pan, PatchSize(1));
    padSize(2) = PatchSize(2) - mod(width_Pan, PatchSize(2));
    im_pad_Pan = padarray (Pan, padSize, 0, 'post');
    
    %MS应为PatchSize/Scale的倍数
    [height_MS, width_MS] = size(MS);
    if mod( PatchSize(1), Scale)~=0 && mod( PatchSize(2), Scale)~=0
        error('块的大小应为分辨率参数的整数倍！');
    end
    padSize(1) = PatchSize(1)/Scale - mod(height_MS, PatchSize(1)/Scale);
    padSize(2) = PatchSize(2)/Scale - mod(width_MS, PatchSize(2)/Scale);
    im_pad_MS = padarray (MS, padSize, 0, 'post');
    %%  取块，并保存到指定文件夹
    NumPatchs = 0;
    [height_pad, width_pad, nChannel_pad] = size(im_pad_Pan);
    for m = 2:height_pad/PatchSize(1)-1%1:height_pad/PatchSize(1)
        for n=2:width_pad/PatchSize(2)-1%1:width_pad/PatchSize(2)
            %% 通过坐标直接匹配方法，找到与MS块最匹配的全色影像块
            
            %取出原始全色（1024X1024），原始分辨率融合算法的输入之一
            row_start = (m-1)*PatchSize(1)+1;
            row_end = m*PatchSize(1);
            col_start = (n-1)*PatchSize(2)+1;
            col_end = n*PatchSize(2);
            patch_Pan = im_pad_Pan(row_start:row_end,...
                                                       col_start:col_end,:);%原始分辨率全色影像
        
            %原始多光谱(256X256X4)，原始分辨率融合算法的输入之二
            %根据MS和Pan对应的地理范围一致进行选择；

            %获得全色图像指定行列对应的地理坐标范围 lon, lat
            [xWorld,yWorld]  = intrinsicToWorld(R_Pan, [col_start, col_end], [row_start, row_end]);
            
            %根据地理坐标范围，获得其再MS图像中的行列范围
           [rows, cols] =  worldToDiscrete(R_MS, xWorld,yWorld);
            
            %Select the best aligned MS image
            patch_MS = im_pad_MS(rows(1):rows(2),...
                                                    cols(1):cols(2),:);%也可作为将分辨率训练的理想值，用于深度学习的训练以及与降分辨率后融合结果进行对比；
            % 
            if ~isequal(size(patch_MS),[PatchSize(1)/Scale, PatchSize(2)/Scale, dim_MS])
                tmp_MS =  zeros(PatchSize(1)/Scale, PatchSize(2)/Scale, dim_MS);
                for  j = 1:dim_MS
                   tmp_MS(:, :, j) = imresize(patch_MS(:, : , j), [PatchSize(1)/Scale, PatchSize(2)/Scale]);
                end
             %patch_MS：原始分辨率-多光谱影像
            patch_MS = tmp_MS;               
            end
            
                        %不采用可能为空值的区域
            if numel(find(patch_Pan==0))/(PatchSize(1)*PatchSize(2))>0.03
                continue;
            end
%             %% Final products
%             %原始分辨率数据集：
%             %patch_MS：原始分辨率-多光谱影像；
%             %patch_Pan：原始分辨率-全色影像；
%             %patch_MS_Up：原始分辨率-上采样后的多光谱影像
% %             patch_MS_Up =  interpGeneral(patch_MS, Scale, tap,tag_interp,1,1);
%             patch_MS_Up = imresize(patch_MS, Scale , 'bilinear' );
%             
%             %降低分辨率后数据集（用于深度学习融合训练和监督结果评价）：
%             %patch_MS_LR：降低分辨率后-多光谱影像；
%             %patch_Pan_LR：降低分辨率后-全色影像；
%             %patch_MS_LR_Up：降低分辨率后-多光谱影像（upsample 到patch_patch_Pan_LR，用于深度学习融合训练、降和）
%             [patch_MS_LR, patch_Pan_LR] = resize_images(patch_MS, patch_Pan, Scale, SensorName);
%             
%             % Upsampling
%             bicubic = 1;
%             if bicubic == 1
%                 H = zeros(size(patch_Pan_LR,1),size(patch_Pan_LR,2),size(patch_MS_LR,3));
%                 for idim = 1 : size(patch_MS_LR,3)
%                     H(:,:,idim) = imresize(patch_MS_LR(:,:,idim),Scale);
%                 end
%                 patch_MS_LR_Up = H;
%             else
%                 patch_MS_LR_Up = interp23tap(patch_MS_LR,Scale);
%             end
            
            %不同下采样方法的尝试
            %{
            %M2 按照Wald protocol, 先Gaussian-MTF低通滤波再下采样+imresize空间插值方法上采样
            %按照Wald protocol, 先Gaussian-MTF低通滤波再下采样
            % 降分辨率后的模拟全色(256X256), 可用于深度学习模型训练的输入值之一
            patch_Pan_LR =  MTF_PAN(patch_Pan, sensorName, Scale);
            patch_Pan_LR= imresize(patch_Pan_LR,1/Scale,'nearest');

            %降分辨率后的模拟多光谱(64X64X4), 可用于深度学习模型训练的输入值之二a
            patch_MS_LR = MTF(patch_MS, sensorName, Scale );
            patch_MS_LR= imresize(patch_MS_LR,1/Scale,'nearest');

            %将模拟多光谱图像采样到256X256X4，可用于深度学习模型训练的输入值之二b
            patch_MS_LR_Up = imresize(patch_MS_LR, Scale , 'bilinear' );
            %}
            
            
            %图像对展示
            % figure
            h = montage(...
                {mat2gray(patch_Pan), ...
                mat2gray(patch_MS(:,:,4:-1:2))}, ...
                'BorderSize',10,'BackgroundColor','white')
            title('全色图像 (左)和多光谱图像 (右)');
            %}
            %% 数据保存
            % 将一组数据以mat格式传到对应的文件夹里面，并保留对应的缩略图
            %
%           saveDir =[ 'H:\Benchmark\',pathList{i}(PathLen+1:end-12)];%设置对应保存路径            
            saveDir_Pan =[ '.\Benchmark_Output\GF1\1',pathList{i}(PathLen+1:end-12),'patch_Pan\'];%设置对应保存路径
            saveDir_MS =[ '.\Benchmark_Output\GF1\1',pathList{i}(PathLen+1:end-12),'patch_MS\'];%设置对应保存路径
            if ~exist(saveDir_Pan,'dir')%待保存的图像文件夹不存在，就建文件夹
                mkdir(saveDir_Pan)
            end
            if ~exist(saveDir_MS,'dir')%待保存的图像文件夹不存在，就建文件夹
                mkdir(saveDir_MS)
            end
            NumPatchs = NumPatchs+1;
            formatSpec = '保存第%d- %d个图像对！\n';
            fprintf(formatSpec, i, NumPatchs);
            
%             %保存融合数据集重新命名
%             Pan= patch_Pan;
%             MS = patch_MS;
%             MS_Up =  patch_MS_Up;
%             Pan_LR = patch_Pan_LR;
%             MS_LR = patch_MS_LR;
%             MS_LR_Up = patch_MS_LR_Up;
%             
%             %参数保存
%             Paras.ratio = Scale;%分辨率
%             Paras.sensor = SensorName;%传感器类型
%             Paras.intre = 'bicubic';%插值方式
%             
%             %保存融合数据 以及对应缩略图
%             filename = [saveDir,num2str(NumPatchs)];
%             save([filename,'.mat'],'Pan', 'MS', 'MS_Up',...
%                 'Pan_LR', 'MS_LR', 'MS_LR_Up', 'Paras')  % function form

%             I_PRACS = tmpData.I_PRACS;
%             I_PRACS(I_PRACS>2.^11-1) = 2.^11-1;
%             I_PRACS = uint16(I_PRACS);
            
            patch_MS(patch_MS>2.^11-1) = 2.^11-1;
            patch_MS = uint8(patch_MS);
            saveName = [saveDir_Pan,num2str(NumPatchs),'.tif'];
            multibandwrite(patch_MS,saveName,'bsq');
            
            patch_Pan(patch_Pan>2.^11-1) = 2.^11-1;
            patch_Pan = uint8(patch_Pan);
            saveName = [saveDir_MS,num2str(NumPatchs),'.tif'];
            multibandwrite(patch_Pan,saveName,'bsq');
            

%             saveas(h,[filename,'.jpg']);
        end
    end
end
