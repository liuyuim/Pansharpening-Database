function [] = Benchmark2testDRDiySize (PathDir, panSize, SaveDir,Num)
    PanSize = 256; %设置原多光谱的边长尺寸
    % panSize = 64; %设置新多光谱的边长尺寸
    SaveDir  = fullfile(SaveDir,['Test_DR',num2str(panSize)]);
    % 得到新图像边长尺寸
    gtSize = panSize;
    lmsSize = panSize; 
    msSize = panSize/4;
    
    % 原图像单边可以截取 n 个新图像
    n = PanSize/panSize; 

    %定义空的矩阵用于存放新mat文件中四个矩阵
    gt = [];
    lms = [];
    ms= [];
    pan = [];

    %循环i遍历文件夹内容并load进工作区 截取和联结
    a=dir(fullfile(PathDir,'*.mat'));%列出文件夹内容

    breakflag=0; %利用标签实现跳出两级循环
    NumImg_s = 0;%计数变量
    for i=1:length(a)
        % 如果是.或者..目录则跳过
        if ~isempty(regexp(a(i).name, '[NCHW](_[NCHW]){3}\.mat', 'once')) % 匹配任何以 N、C、H、W 这些字符排列组合，并且后面跟着三个 _ 和相同的字符排列组合，最后以 .mat 结尾的字符串。这样，它就可以同时匹配 N_H_W_C.mat、N_C_H_W.mat、W_H_C_N.mat 和 C_W_H_N.mat。
            continue;
        end
        load(fullfile(PathDir,a(i).name));
        for j=1:n
            
            if breakflag==1
                break;
            end
            for k=1:n
            if(NumImg_s==Num)
                fprintf(".");
                breakflag=1; break ;  % 跳出两级循环% return;  % 调用return来退出函数，模拟跳出两级循环 % continue;   
            end

            %依次截取一小块作为符合像素要求的图像，暂时命名img_tem
            MS = double(MS);
            gt = MS((j-1)*gtSize+1:(j-1)*gtSize+gtSize,(k-1)*gtSize+1:(k-1)*gtSize+gtSize,:);

            %依次截取一小块作为符合像素要求的图像，暂时命名img_tem
            MS_LR_Up = double(MS_LR_Up);
            lms = MS_LR_Up((j-1)*lmsSize+1:(j-1)*lmsSize+lmsSize,(k-1)*lmsSize+1:(k-1)*lmsSize+lmsSize,:);
            
            %依次截取一小块作为符合像素要求的图像，暂时命名img_tem
            MS_LR = double(MS_LR);
            ms = MS_LR((j-1)*msSize+1:(j-1)*msSize+msSize,(k-1)*msSize+1:(k-1)*msSize+msSize,:);
            
            %依次截取一小块作为符合像素要求的图像，暂时命名img_tem
            Pan_LR = double(Pan_LR);
            pan = Pan_LR((j-1)*panSize+1:(j-1)*panSize+panSize,(k-1)*panSize+1:(k-1)*panSize+panSize,:);
            
            if ~exist(SaveDir,'dir') % 创建文件夹
                mkdir(SaveDir)
            end
            saveName = fullfile(SaveDir,[num2str(NumImg_s+1),'.mat']);
            save(saveName, 'gt', 'lms', 'ms', 'pan','Paras');
            fprintf("开始保存...稍等，请勿关闭...\n");
    
            %输出进度
            NumImg_s = NumImg_s+1;
            formatSpec = '已处理文件夹%s ！生成第 %d 个新 文件！\n';
            fprintf(formatSpec,PathDir,NumImg_s);
            end
        

        end       
    end


end
