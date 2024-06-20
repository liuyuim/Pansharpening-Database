
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 采用benchmark数据集进行融合实验，在高低两个分辨率尺度上对融合结果进行评价
% 对比方法采用 Pansharpening Tool ver 1.3中的方法；
% 对比指标主要是


clc
clear
close all
% addpath(genpath('./Toolbox\'));
%%
%全部Fusion数据所在路径
% ImgPaths = '.\Benchmark_Output\GF1\1\';
% ImgPaths = '..\fenleiRS\GF1\Js\';
ImgPaths = '.\temp\WeiBiaoDuoLei\';
%数据保存路径
% saveDir = '.\FusionComparsionsResults\GF1\1\';%设置对应保存路径
saveDir = '.\temp\WeiBiaoDuoLeiResults\';%设置对应保存路径

if ~exist(saveDir,'dir')%待保存的图像文件夹不存在，就建文件夹
    mkdir(saveDir)
end
%%

%列出传感器文件夹内所有的融合
listing = dir([ImgPaths,'**/*.mat']) ;
NumImgs = size(listing,1);
MatrixResults_Fu = zeros(19, 5, NumImgs);%存储融合结果的矩阵
MatrixResults_DR = zeros(19, 5, NumImgs);%存储j降分辨率融合结果的矩阵
% parfor i = 1:NumImgs
 for i = 1:NumImgs

    
    formatSpec = '处理%d个图像中第%d个！\n';
    fprintf(formatSpec, NumImgs, i);
    
    loadImgPath = [listing(i).folder,'\',listing(i).name];
    imgData = load(loadImgPath);
    
    %Full resoution results
    I_MS_LR = double(imgData.MS); % MS image;
    I_MS =  double(imgData.MS_Up);% MS image upsampled to the PAN size;
    I_PAN = double(imgData.Pan); %Pan
    Params = imgData.Paras;
    [MatrixImage_Fu, MatrixResult_Fu] = FusionAndEvaluateOnFullResolution (I_MS, I_MS_LR, I_PAN, Params);
    
    %Reduced resoution results
    I_GT = double(imgData.MS); %ground truth
    I_PAN = double(imgData.Pan_LR);% low resolution Pan image
    I_MS  = double(imgData.MS_LR_Up);% low resolution MS image upsampled at  low resolution  PAN scale;
    I_MS_LR = double(imgData.MS_LR);% low resolution MS image
    [MatrixImage_DR, MatrixResult_DR] = FusionAndEvaluateOnReduceResolution (I_GT, I_MS, I_PAN, I_MS_LR, Params);
    
    MatrixResults_DR(:,:,i) = MatrixResult_DR;
    MatrixResults_Fu(:,:,i)= MatrixResult_Fu;
    %% 保存每组图像的融合结果
    saveName = fullfile(saveDir,[num2str(i),'.mat']);
    %{
    h1 = montage(histeq(mat2gray(MatrixImage_Fu(:,:,4:-1:2,:))),'BorderSize',10,'BackgroundColor','white');
    titleImages1 = {'PAN','EXP','PCA','IHS','Brovey','BDSD','GS','GSA','PRACS','HPF','SFIM','Indusion','ATWT','AWLP','ATWT M2','ATWT M3','MTF GLP','MTF GLP HPM PP','MTF GLP HPM','MTF GLP CBD'};
%     saveas(h,[filename,'.jpg']);

%      title('全色图像 (左)和多光谱图像 (右)');
    save(saveName,

    h2 = montage(histeq(mat2gray(MatrixImage_DR(:,:,4:-1:2,:))),'BorderSize',10,'BackgroundColor','white');
    titleImages2 = {'GT','EXP','PCA','IHS','Brovey','BDSD','GS','GSA','PRACS','HPF','SFIM','Indusion','ATWT','AWLP','ATWT M2','ATWT M3','MTF GLP','MTF GLP HPM PP','MTF GLP HPM','MTF GLP CBD'};
    %}
    %数据量太大，故隔十个保存一组分类结果
    %当正数与负数取余时，当得到的余数结果的符号希望跟被除数 (x)一样，用rem ()函数；当得到的余数结果的符号希望跟除数 (y)一样，用mod ()函数
    if rem(i, 10) == 0
        save(saveName,'MatrixImage_Fu', 'MatrixImage_DR', 'loadImgPath', 'MatrixResult_DR','MatrixResult_Fu');% 单组数据约0.6G
    else
        save(saveName, 'loadImgPath', 'MatrixResult_DR','MatrixResult_Fu');% 单组数据约0.6G
    end
end
saveName = fullfile(saveDir,'all.mat');
save(saveName, 'MatrixResults_Fu', 'MatrixImage_DR','ImgPaths');