function [] = Benchmark2TrainValidation (PathDir, NumMat)
    SaveDir = PathDir;

    GTSize = 256; %设置原多光谱的边长尺寸
    gtSize = 64; %设置新多光谱的边长尺寸

    % 得到新图像边长尺寸
    lmsSize = gtSize; 
    msSize = gtSize/4;
    panSize = gtSize;
    
    % 原图像单边可以截取 n 个新图像
    n = GTSize/gtSize; 

    %定义空的矩阵用于存放新mat文件中四个矩阵
    gt = [];
    lms = [];
    ms= [];
    pan = [];

    % 如果存在老数据则删除
    saveName = fullfile(SaveDir,'N_H_W_C.mat');
    if exist(saveName,'file') == 2 % 存在返回2，若不存在返回0
        delete(saveName);
    end
    saveName = fullfile(SaveDir,'W_H_C_N.mat');
    if exist(saveName,'file') == 2 % 存在返回2，若不存在返回0
        delete(saveName);
    end
    saveName = fullfile(SaveDir,'N_C_H_W.mat');
    if exist(saveName,'file') == 2 % 存在返回2，若不存在返回0
        delete(saveName);
    end
    saveName = fullfile(SaveDir,'C_W_H_N.mat');
    if exist(saveName,'file') == 2 % 存在返回2，若不存在返回0
        delete(saveName);
    end
    saveName = fullfile(SaveDir,'hdf5.h5');
    if exist(saveName,'file') == 2 % 存在返回2，若不存在返回0
        delete(saveName);
    end

    %循环i遍历文件夹内容并load进工作区 截取和联结gt
    a=dir(fullfile(PathDir,'*.mat'));%列出文件夹内容

    breakflag=0; %利用标签实现跳出两级循环
    NumImg_s = 0;%计数变量
    for i=1:length(a)
        load(fullfile(PathDir,a(i).name));
        for j=1:n
            if breakflag==1
                break;
            end
            for k=1:n
            if(NumImg_s==NumMat)
                fprintf(".");
                breakflag=1; break ;  % 跳出两级循环% return;  % 调用return来退出函数，模拟跳出两级循环 % continue;   
            end
            %依次截取一小块作为符合像素要求的图像，暂时命名img_tem
            MS = double(MS);
            img_tem = MS((j-1)*gtSize+1:(j-1)*gtSize+gtSize,(k-1)*gtSize+1:(k-1)*gtSize+gtSize,:);
            %利用cat联结（按第几维来联结，被联结的图，要联结的）
            gt = cat(4, gt, img_tem);

            %输出进度
            NumImg_s = NumImg_s+1;
            formatSpec = '已处理文件夹%s ！生成第 %d 个新gt文件！\n';
            fprintf(formatSpec,PathDir,NumImg_s);
            end
        end       
    end
    
    %循环i遍历文件夹内容并load进工作区 截取和联结lms
    a=dir(fullfile(PathDir,'*.mat'));%列出文件夹内容
    NumImg_s = 0;%计数变量
    for i=1:length(a)
        load(fullfile(PathDir,a(i).name));
        for j=1:n
            for k=1:n
            if(NumImg_s==NumMat)
             % fprintf(".");
             continue;   
            end
            %依次截取一小块作为符合像素要求的图像，暂时命名img_tem
            MS_LR_Up = double(MS_LR_Up);
            img_tem = MS_LR_Up((j-1)*lmsSize+1:(j-1)*lmsSize+lmsSize,(k-1)*lmsSize+1:(k-1)*lmsSize+lmsSize,:);
            lms = cat(4, lms, img_tem);

            %输出进度
            NumImg_s = NumImg_s+1;
            formatSpec = '已处理文件夹%s ！生成第 %d 个新lms文件！\n';
            fprintf(formatSpec,PathDir,NumImg_s);
            end
        end       
    end


    %循环i遍历文件夹内容并load进工作区 截取和联结ms
    a=dir(fullfile(PathDir,'*.mat'));%列出文件夹内容
    NumImg_s = 0;%计数变量
    for i=1:length(a)
        load(fullfile(PathDir,a(i).name));
        for j=1:n
            for k=1:n
            if(NumImg_s==NumMat)
             % fprintf(".");
             continue;   
            end
            %依次截取一小块作为符合像素要求的图像，暂时命名img_tem
            MS_LR = double(MS_LR);
            img_tem = MS_LR((j-1)*msSize+1:(j-1)*msSize+msSize,(k-1)*msSize+1:(k-1)*msSize+msSize,:);
            ms = cat(4, ms, img_tem);

            %输出进度
            NumImg_s = NumImg_s+1;
            formatSpec = '已处理文件夹%s ！生成第 %d 个新ms文件！\n';
            fprintf(formatSpec,PathDir,NumImg_s);
            end
        end       
    end

    %循环i遍历文件夹内容并load进工作区 截取和联结pan
    a=dir(fullfile(PathDir,'*.mat'));%列出文件夹内容
    NumImg_s = 0;%计数变量
    for i=1:length(a)
        load(fullfile(PathDir,a(i).name));
        for j=1:n
            for k=1:n
            if(NumImg_s==NumMat)
             % fprintf(".");
             continue;   
            end
            %依次截取一小块作为符合像素要求的图像，暂时命名img_tem
            Pan_LR = double(Pan_LR);
            img_tem = Pan_LR((j-1)*panSize+1:(j-1)*panSize+panSize,(k-1)*panSize+1:(k-1)*panSize+panSize,:);
            pan = cat(3, pan, img_tem);

            %输出进度
            NumImg_s = NumImg_s+1;
            formatSpec = '已处理文件夹%s ！生成第 %d 个新pan文件！\n';
            fprintf(formatSpec,PathDir,NumImg_s);
            end
        end       
    end

    % 把矩阵的维度平移, 将数组 A 的维度移动 n 个位置。当 n 为正整数时，shiftdim 向左移动维度；当 n 为负整数时，向右移动维度。
    % 例如，如果 A 是 2×3×4 数组，则 shiftdim(A,2) 返回 4×2×3 数组。
    gt_N_H_W_C = shiftdim(gt,3);
    lms_N_H_W_C = shiftdim(lms,3);
    ms_N_H_W_C = shiftdim(ms,3);
    pan_N_H_W_C = shiftdim(pan,2);
        
    fprintf("开始保存...稍等，请勿关闭...\n");
    if ~exist(SaveDir,'dir') % 创建文件夹
        mkdir(SaveDir)
    end
    
    gt = gt_N_H_W_C;
    lms = lms_N_H_W_C;
    ms = ms_N_H_W_C;
    pan = pan_N_H_W_C;

    saveName = fullfile(SaveDir,'N_H_W_C.mat');
    save(saveName, 'gt', 'lms', 'ms', 'pan' ,'Paras'); 
    
    

    % WSDFNet：banchmaker(N*H*W*C) ——> WSDFNet.tensor.sh(N*C*H*W) 
    gt = permute(gt_N_H_W_C,[1 4 2 3]);
    lms = permute(lms_N_H_W_C,[1 4 2 3]);
    ms = permute(ms_N_H_W_C,[1 4 2 3]);
    pan = permute(pan_N_H_W_C,[1 4 2 3]);    % 
    saveName = fullfile(SaveDir,'N_C_H_W.mat');
    save(saveName, 'gt', 'lms', 'ms', 'pan' ,'Paras'); 

    % % LPPN：banchmaker(N*H*W*C) ——> LPPN.tensor.sh(N*H*W*C) ——> h5py.File(C.W.H.N) 
    % gt = permute(gt_N_H_W_C,[4 3 2 1]);
    % lms = permute(lms_N_H_W_C,[4 3 2 1]);
    % ms = permute(ms_N_H_W_C,[4 3 2 1]);
    % pan = permute(pan_N_H_W_C,[4 3 2 1]);
    % saveName = fullfile(SaveDir,'C_W_H_N.mat');
    % save(saveName, 'gt', 'lms', 'ms', 'pan' ,'Paras');

    % % WSDFNet：banchmaker(N*H*W*C) ——> WSDFNet.tensor.sh(N*C*H*W) ——> h5py.File(W*H*C*N) 
    % gt = permute(gt_N_H_W_C,[3 2 4 1]);
    % lms = permute(lms_N_H_W_C,[3 2 4 1]);
    % ms = permute(ms_N_H_W_C,[3 2 4 1]);
    % pan = permute(pan_N_H_W_C,[3 2 4 1]);    
    % saveName = fullfile(SaveDir,'W_H_C_N.mat');
    % save(saveName, 'gt', 'lms', 'ms', 'pan' ,'Paras'); 
    
    % CreatHdf5
    hdf5_file = fullfile(SaveDir,'hdf5.h5');
    Mat2CreatHdf5 (hdf5_file, gt, lms, ms, pan);

end