function [] = TifOutputErjiDir2Mat (FusionImgYijiPath,saveDir,SensorName)
addpath(genpath('.\Toolbox\'));
    
    % 遍历出二级目录名
    ErjiDir_list = dir(FusionImgYijiPath) ;  % 二级目录列表
    ErjiDir_list_Nums = size(ErjiDir_list,1);  % 二级目录个数 包括 .和..
    for i_ErjiDir = 3 : ErjiDir_list_Nums
        %列出当前二级文件夹内所有的文件
        ErjiPath = fullfile(FusionImgYijiPath,ErjiDir_list(i_ErjiDir).name); 
        FusionImg_list = dir([ErjiPath,'\','*.tif']) ;
        
        % 在当前二级目录处理每一个Tif         
        NumImgs = size(FusionImg_list,1);  % mat个数 . ..
        for i = 1:NumImgs
        
            formatSpec = '正在处理目录 %s！%d个图像中第%d个！\n';
            fprintf(formatSpec,ErjiPath, NumImgs, i);
            
    %         % 校验 从当前两个文件夹 分别取出的 mat文件名 是否一致            
    %         MSlist_verify = MSlist(i).name;   
    %         Panlist_verify = Panlist(i).name;
    %         %验证两者是否一致
    %         if ~isequal(MSlist_verify, Panlist_verify)
    %             fprintf("当前从 MS和Pan文件夹分别取出的 mat文件名 不一致");
    %             break;
    %         end
                
            % 然后再正常运行
            
            %获取图像传感器基本信息
    %         SensorName = pathList{i}(PathLen+1:end-15);
            %读取多光谱影像
            [FusionImg,R_Output] = readgeoraster([ErjiPath,'\', FusionImg_list(i).name]);
            %     info_MS = geotiffinfo([pathList{i}, 'MS.tif']);
    %         [height_MS, width_MS, dim_MS] = size(MS);
            %读取全色影像
    %         [Pan, R_Pan] = readgeoraster([PanDataPath, Panlist(i).name]);
    
    %         %根据影像分辨率的差异，确定放缩倍数（一般为4倍）
    %         %     Scale = round ((R_MS.CellExtentInWorldX/R_Pan.CellExtentInWorldX + R_MS.CellExtentInWorldY/R_Pan.CellExtentInWorldY)/2);
            Scale = 4;
    %         %将全色影像调整为多光谱影像大小的Scale倍,同时更新Referencing Object
    %         Pan = imresize(Pan, [height_MS, width_MS]*Scale, 'bicubic');
    %         R_Pan.RasterSize = [height_MS, width_MS]*Scale;%The resized image has the same limits as the original, just a smaller size, so copy the referencing object and reset its RasterSize property.
    
    
            %原始分辨率数据集：
            %patch_MS：原始分辨率-多光谱影像；
            %patch_Pan：原始分辨率-全色影像；
            %patch_MS_Up：原始分辨率-上采样后的多光谱影像
            %patch_MS_Up =  interpGeneral(patch_MS, Scale, tap,tag_interp,1,1);
            
    %         patch_MS = MS;
    %         patch_Pan = Pan;        
    %         patch_MS_Up = imresize(patch_MS, Scale , 'bilinear' );
    %         
    %         %降低分辨率后数据集（用于深度学习融合训练和监督结果评价）：
    %         %patch_MS_LR：降低分辨率后-多光谱影像；
    %         %patch_Pan_LR：降低分辨率后-全色影像；
    %         %patch_MS_LR_Up：降低分辨率后-多光谱影像（upsample 到patch_patch_Pan_LR，用于深度学习融合训练、降和）
    %         % SensorName = 'GF';
    %         [patch_MS_LR, patch_Pan_LR] = resize_images(patch_MS, patch_Pan, Scale, SensorName);
    %         
    %         % Upsampling
    %         bicubic = 1;
    %         if bicubic == 1
    %             H = zeros(size(patch_Pan_LR,1),size(patch_Pan_LR,2),size(patch_MS_LR,3));
    %             for idim = 1 : size(patch_MS_LR,3)
    %                 H(:,:,idim) = imresize(patch_MS_LR(:,:,idim),Scale);
    %             end
    %             patch_MS_LR_Up = H;
    %         else
    %             patch_MS_LR_Up = interp23tap(patch_MS_LR,Scale);
    %         end
    
            
            
            %图像对展示
            % figure
            h = montage(...
                {mat2gray(FusionImg(:,:,4:-1:2)), ...
                mat2gray(FusionImg(:,:,4:-1:2))}, ...
                'BorderSize',10,'BackgroundColor','white')
            title('全色图像 (左)和多光谱图像 (右)');
            %}
    %% 数据保存
    % 将一组数据以mat格式传到对应的文件夹里面，并保留对应的缩略图
    % 
    % saveDir =[ 'H:\Benchmark\',pathList{i}(PathLen+1:end-12)];%设置对应保存路径            
    % end
    % NumPatchs = NumPatchs+1;
    % formatSpec = '保存第%d- %d个图像对！\n';
    % fprintf(formatSpec, i, NumPatchs);
    
            %保存融合数据集重新命名
    %         Pan= patch_Pan;
    %         MS = patch_MS;
    %         MS_Up =  patch_MS_Up;
    %         Pan_LR = patch_Pan_LR;
    %         MS_LR = patch_MS_LR;
    %         MS_LR_Up = patch_MS_LR_Up;
            output = FusionImg;
            %参数保存
            Paras.ratio = Scale;%分辨率
            Paras.sensor = SensorName;%传感器类型
            Paras.intre = 'bicubic';%插值方式
    
            
            suffix = find('.'== FusionImg_list(i).name); %寻找后缀名前面的标志"."
            imname = FusionImg_list(i).name(1:suffix-1); %取文件名第一位到.的前一位字符
            saveErjiDir = fullfile(saveDir,ErjiDir_list(i_ErjiDir).name);
            saveName = fullfile(saveErjiDir,imname);
            if ~exist(saveErjiDir,'dir')%待保存的图像文件夹不存在，就建文件夹
                mkdir(saveErjiDir)            
            end
            save(saveName, 'output', 'Paras');
            
        end
    end
        
    fprintf("已完成，请到%s查看！\n ",saveDir);
end
