function [] = MatMSPan2Benchmark (MSDataPath,PanDataPath,saveDir,SensorName)
addpath(genpath('.\Toolbox\'));

    % 在当前二级目录处理每一个mat
    MSlist = dir([MSDataPath,'**/*.mat']) ;
    Panlist = dir([PanDataPath,'**/*.mat']) ;
    NumImgs = size(dir(MSDataPath),1)-2;  % mat个数 . ..
    for i = 1:NumImgs
    
        formatSpec = '正在处理目录 %s！%d个图像中第%d个！\n';
        fprintf(formatSpec,MSDataPath, NumImgs, i);
        
        % 校验 当前从 TestOutput和TestData文件夹 分别取出的 mat文件名 是否一致            
        MSlist_verify = MSlist(i).name;   
        Panlist_verify = Panlist(i).name;
        %验证两者是否一致
        if ~isequal(MSlist_verify, Panlist_verify)
            fprintf("当前从 MS和Pan文件夹分别取出的 mat文件名 不一致");
            break;
        end
            
        % 然后再正常运行
        
        %把mat文件加载进来
        load([MSlist(i).folder,'\',MSlist(i).name]); 
        load([Panlist(i).folder,'\',Panlist(i).name]); 
        
        %原始分辨率数据集：
        %patch_MS：原始分辨率-多光谱影像；
        %patch_Pan：原始分辨率-全色影像；
        %patch_MS_Up：原始分辨率-上采样后的多光谱影像
        %patch_MS_Up =  interpGeneral(patch_MS, Scale, tap,tag_interp,1,1);
        
        % UNB GF1 106号以后是I_MS，I_PAN的变量名称形式,检查工作区是否存在变量 I_MS，I_PAN ,改为imgMS，imgPAN 
        if exist('I_MS', 'var')
            % 重命名变量为 imgMS I_PAN
            imgMS = I_MS;
            clear I_MS;
            disp('I_MS变量已重命名为 imgMS');
        end
        if exist('I_PAN', 'var')
            imgPAN = I_PAN;
            clear I_PAN;
            disp('I_PAN变量已重命名为 imgPAN');
        end
        patch_MS = double(imgMS);
        patch_Pan = double(imgPAN);
        
        % 如果是8波段，就把2357波段抽出来
        if size(patch_MS,3)==8
            patch_MS_tmp = patch_MS;
            clear patch_MS;
            patch_MS(:,:,1) = patch_MS_tmp(:,:,2);
            patch_MS(:,:,2) = patch_MS_tmp(:,:,3);
            patch_MS(:,:,3) = patch_MS_tmp(:,:,5);
            patch_MS(:,:,4) = patch_MS_tmp(:,:,7);
        end    
        Scale = 4;
        patch_MS_Up = imresize(patch_MS, Scale , 'bilinear' );
        
        %降低分辨率后数据集（用于深度学习融合训练和监督结果评价）：
        %patch_MS_LR：降低分辨率后-多光谱影像；
        %patch_Pan_LR：降低分辨率后-全色影像；
        %patch_MS_LR_Up：降低分辨率后-多光谱影像（upsample 到patch_patch_Pan_LR，用于深度学习融合训练、降和）
        % SensorName = 'GF';        
        [patch_MS_LR, patch_Pan_LR] = resize_images(patch_MS, patch_Pan, Scale, SensorName);

        % Upsampling
        bicubic = 1;
        if bicubic == 1
            H = zeros(size(patch_Pan_LR,1),size(patch_Pan_LR,2),size(patch_MS_LR,3));
            for idim = 1 : size(patch_MS_LR,3)
                H(:,:,idim) = imresize(patch_MS_LR(:,:,idim),Scale);
            end
            patch_MS_LR_Up = H;
        else
            patch_MS_LR_Up = interp23tap(patch_MS_LR,Scale);
        end

        
        
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
% saveDir =[ 'H:\Benchmark\',pathList{i}(PathLen+1:end-12)];%设置对应保存路径            
% end
% NumPatchs = NumPatchs+1;
% formatSpec = '保存第%d- %d个图像对！\n';
% fprintf(formatSpec, i, NumPatchs);

        %保存融合数据集重新命名
        Pan= patch_Pan;
        MS = patch_MS;
        MS_Up =  patch_MS_Up;
        Pan_LR = patch_Pan_LR;
        MS_LR = patch_MS_LR;
        MS_LR_Up = patch_MS_LR_Up;
        
        %参数保存
        Paras.ratio = Scale;%分辨率
        Paras.sensor = SensorName;%传感器类型
        Paras.intre = 'bicubic';%插值方式

        if ~exist(saveDir,'dir')%待保存的图像文件夹不存在，就建文件夹
            mkdir(saveDir)            
        end
        
        saveName = fullfile(saveDir,['\'],MSlist(i).name);
        save(saveName, 'Pan', 'MS', 'MS_Up','Pan_LR', 'MS_LR', 'MS_LR_Up', 'Paras');
        
    end
        
        
    fprintf("已完成，请到%s查看！\n ",saveDir);
end
