function [] = Benchmark2testDR (PathDir, SaveDir_DR)

%     %定义空的矩阵用于存放新mat文件中四个矩阵
%     gt = [];
%     lms = [];
%     ms= [];
%     pan = [];

    %列出传感器文件夹内所有的mat
    listing = dir([PathDir,'**/*.mat']) ;
    NumImg = size(listing,1);
    NumImgSum = NumImg ;
    % parfor i = 1:NumImgs
     for i = 1:NumImgSum
    
        formatSpec = '正在处理%d个图像中第%d个......\n';
        fprintf(formatSpec, NumImgSum, i);
        
        loadMatPath = [listing(i).folder,'\',listing(i).name]; %listing列表中的第i个目录和文件名拼成要加载的mat路径
        imgData = load(loadMatPath);
        %截取和联结gt
        gt = double(imgData.MS);           
 
        %截取和联结lms
        lms = double(imgData.MS_LR_Up);        
  
        %截取和联结ms
        ms = double(imgData.MS_LR);         
  
        %截取和联结pan
        pan = double(imgData.Pan_LR);         
        
        %Paras
        Paras = imgData.Paras;

        %输出进度
        NumImg = NumImg+1;
            
        
%         %把矩阵的维度平移
%         gt = shiftdim(gt,3);
%         lms = shiftdim(lms,3);
%         ms = shiftdim(ms,3);
%         pan = shiftdim(pan,2);
               
    %     %参数保存
    %     Paras.ratio = Scale;%分辨率
    %     Paras.sensor = SensorName;%传感器类型
    %     Paras.intre = 'bicubic';%插值方式
    
        % 开始保存 
        % saveName = fullfile(PathDir,'train.mat');
    %     saveName = fullfile(SaveDir,PathDir);
    %     saveName = fullfile(PathDir,a(i).name);loadMatPath
    %     saveName = fullfile(saveDir,[num2str(i),'.mat']);
            
%         loadMatPath_strsplit = strsplit(listing(i).folder,'\'); %把路径用split以\分割
%         loadMatPath_strsplit_char = char(loadMatPath_strsplit(5)); %分割完的结果转成字符型作为二级目录
%         SavePath = fullfile(SaveDir,loadMatPath_strsplit_char); %实际保存mat的绝对路径是由上面定义的临时一级目录加上二级目录
%         SaveName = fullfile(SaveDir,loadMatPath_strsplit_char,listing(i).name); %保存的mat文件名还用原文件名
                
        SaveName = fullfile(SaveDir_DR,listing(i).name); %保存的mat文件名还用原文件名，不用二级目录      
        if ~exist(SaveDir_DR,'dir')
            mkdir(SaveDir_DR)
        end
        
        save(SaveName, 'gt', 'lms', 'ms', 'pan','Paras' ); % training.mat testing.mat, 'Paras'
        formatSpec = '完成，保存至【SaveName】%s\n';
        fprintf(formatSpec, SaveName);
%         formatSpec = '%保存完毕d个图像中第%d个！\n';an = strsplit(datasetCur,'/');str2 = char(loadMatPath_strsplit(5))
% loadMatPath_strsplit = strsplit(listing(i).folder,'\'); loadMatPath
% loadMatPath_strsplit = strsplit(listing(i).folder,'\');;
% str2 = char(loadMatPath_strsplit(5))

%         fprintf(formatSpec, NumImgSum, i);
    end
end
