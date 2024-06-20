%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%                        说明                               %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 本脚本使用Demo_CreateFusionPairs生成的mat文件进行加工，批量制作成深度学习实验所用的数据集
%
% 【数据集格式】
% 使用Demo_CreateFusionPairs生成的mat文件包括如下结构
% |--(4)MS 256*256*4 (对应训练集gt 64 64 8)
% |--(2)MS_LR 64*64*4 (对应训练集ms 16 16 8)
% |--(3)MS_LR_Up 256*256*4 (对应训练集lms 64 64 8)
% |--(6)MS_UP 1024*1024*4
% |--(5)PAN 1024*1024
% |--(1)PAN_LR 256*256 (对应训练集pan 64 64)
% |--Paras 1*1
% 
% 降分辨率 监督评价：
%                (1)PAN_LR   |
%                            |--> (4)MS / GT
% (2)MS_LR  ——>  (3)MS_LR_Up |    
% 
% 全分辨率 非监督评价：
%             (5)PAN    |
%                       |--> ?
% (4)MS  ——>  (6)MS_UP  |
% 
% 深度学习论文代码需要格式为：
% |--ms: original multispectral images in .mat format, basically have the size of N*h*w*C 
% |--lms: interpolated multispectral images in .mat format, basically have the size of N*H*W*C 
% |--pan: original panchromatic images in .mat format, basically have the size of N*H*W*1
% |--gt: simulated ground truth images images in .mat format, basically have the size of N*H*W*C 
% 
% PanNet 训练集/验证集 .mat
% |--gt  100    64    64     8 对应(4)MS
% |--lms 100    64    64     8 对应(3)MS_LR_Up
% |--ms  100    16    16     8 对应(2)MS_LR
% |--pan 100    64    64       对应(1)PAN_LR
% 
% PanNet 测试集 降分辨率 监督评价：
% |--gt  256   256     8 对应(4)MS 256*256*4
% |--lms 256   256     8 对应(3)MS_LR_Up 256*256*4
% |--ms  64    64      8 对应(2)MS_LR 64*64*4
% |--pan 256   256	     对应(1)PAN_LR 256*256
% 
% PanNet 测试集 全分辨率 非监督评价：
% |--lms 256   256     8 对应(6)MS_Up 1024*1024*4
% |--ms  64    64      8 对应(4)MS 256*256*4
% |--pan 256   256	     对应(5)PAN 1024*1024



%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 【1 Benchmark数据集的批量制作】
% max(MS(:))
% class(MS)
% prctile(MS(:),100)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% MS和Pan数据分别在两个Mat文件中的数据集（例如NBU数据集）

clc;clear;close all;addpath(genpath('.\Fx\'));

SensorName = 'WV3'; %会作为paras中影像sensor属性内容
MSDataPath='F:\Demo\Data_Dataset\Database\NBU_PansharpRSData\1 Satellite_Dataset\Dataset\6 WorldView-3\MS_256\';
PanDataPath='F:\Demo\Data_Dataset\Database\NBU_PansharpRSData\1 Satellite_Dataset\Dataset\6 WorldView-3\PAN_1024\';
saveDir = 'F:\Demo\Data_Dataset\WV3_Data\Benchmark\';%设置对应保存路径
MatMSPan2Benchmark (MSDataPath,PanDataPath,saveDir,SensorName);

fprintf("所有 mat已制作完成，该环节脚本程序结束！\n");

%% 遥感影像产品一景影像已被切割成MS和Pan图像块的Tif数据，用MSPanTif2Benchmark

clc;clear;close all;addpath(genpath('.\Fx\'));

SensorName = 'QB';
MSDataPath='F:\Demo\Data_Dataset\Database\TifClip_QB\TifClip_MS\';
PanDataPath='F:\Demo\Data_Dataset\Database\TifClip_QB\TifClip_Pan\';
saveDir = 'F:\Demo\Data_Dataset\QB_Data\Benchmark\';%设置对应保存路径
TifMSPan2Benchmark (MSDataPath,PanDataPath,saveDir,SensorName);

fprintf("所有 mat已制作完成，该环节脚本程序结束！\n");

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 【2 训练集和验证集的批量制作】
% 脚本将原mat文件的每一个大图拿出来，截取成需要的小图(代码中各个img_tem),
% 又由于训练集和测试集都是把多个三维影像图叠加在第四维形成mat文件的形式，
% 所以本脚本再把百余个小图(代码中各个img_tem)联结(cat)起来形成叠在一起的矩阵。
% 分别联结成gt、lms、ms、pan四个矩阵后，把这四个保存成一个新的mat文件。
%  
% 调整数组维度格式 生成N_H_W_C.mat、N_C_H_W.mat、W_H_C_N.mat,C_W_H_N.mat，运行时自动删除老数据
% WSDFNet：banchmaker(N*H*W*C) ——> WSDFNet.tensor.sh(N*C*H*W) ——> h5py.File(W*H*C*N)
% gt = permute(gt,[3 2 4 1]);
% 
% LPPN：banchmaker(N*H*W*C) ——> LPPN.tensor.sh(N*H*W*C) ——> h5py.File(C.W.H.N) 
% Train 用nhw, Test h5py用cwhn, Test mat73用nhwc
% gt = permute(gt,[4 3 2 1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;clear;close all;addpath(genpath('.\Fx\'));


fprintf("开始训练集验证集的批量制作！\n"); 
NumMat=100; % 一组数据集中包含的图片张数
SensorNames = {'GF1'}; % %{'GF1','IK','QB','WV2','WV3','WV4'} {'GF1','GF2','JL1','QB','WV2','WV3'}  'GF1','GF2','IK','JL1','QB','WV2','WV3','WV4'
for i = 1:numel(SensorNames)
    Sensor_Data = strcat(SensorNames{i}, '_Data');    % 或者    Sensor_Data = SensorNames{i} + "_Data";
    
    PathDir = fullfile('F:\Demo\Data_Dataset',Sensor_Data,'Train'); %SaveDir = PathDir    
    Benchmark2TrainValidation (PathDir,NumMat);
    
    % SaveDir = fullfile('F:\Demo\Data_Dataset',Sensor_Data,'Test_Tr');    
    % Benchmark2TrainValidationTest (PathDir, SaveDir, NumMat); %训练数据的测试集格式
    
    PathDir = fullfile('F:\Demo\Data_Dataset',Sensor_Data,'Validation'); %SaveDir = PathDir;   
    Benchmark2TrainValidation (PathDir,NumMat);
end

fprintf("所有train/validation mat已制作完成，该环节脚本程序结束！\n");


%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 【3 测试集的批量制作】
% 将生成的Benchmark mat文件内各个图像重新整合制作成测试集
% 设置Benchmark mat文件目录的地址为原一级目录，
% 设置自定义目录为新一级目录，
% 脚本会寻找原一级目录下所有二级目录内的mat文件，依次进行处理
% 每个mat处理完后，会保存在新一级目录下创建对应的二级目录，
% 与原目录结构一致，文件名不变，但文件是新的，也就是制作的测试集数据
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;clear;close all;addpath(genpath('.\Fx\'));


% PathDir='F:\HC550WDC16TO\Shiyan\20231201\GF1_Data\Benchmark\'; %准备制作成测试集的Benchmark文件放入该目录
% SaveDir_Fu='F:\HC550WDC16TO\Shiyan\20231201\GF1_Data\Test_Fu\'; %设置自定义目录为新一级目录
% Benchmark2TestFu (PathDir, SaveDir_Fu); 
% SaveDir_DR='F:\HC550WDC16TO\Shiyan\20231201\GF1_Data\Test_DR\'; %设置自定义目录为新一级目录
% Benchmark2TestDR (PathDir, SaveDir_DR); 


Num = 100;   % 设置新的边长尺寸  256 16*7=112可以用7张
SensorNames = {'GF1' }; %{'GF1','IK','QB','WV2','WV3','WV4'} {'GF1','GF2','JL1','QB','WV2','WV3'}  'GF1','GF2','IK','JL1','QB','WV2','WV3','WV4'
for i = 1:numel(SensorNames)
    Sensor_Data = strcat(SensorNames{i}, '_Data');    % 或者    Sensor_Data = SensorNames{i} + "_Data";    
    for panSize = [1024,512,256,128,64,32]    %[1024,512,256,128,64,32]
        PathDir=fullfile('F:\Demo\Data_Dataset',Sensor_Data,'Benchmark'); %准备制作成测试集的Benchmark文件放入该目录
        SaveDir=fullfile('F:\Demo\Data_Dataset',Sensor_Data); %设置自定义目录为新一级目录
        Benchmark2TestFuDiySize (PathDir, panSize, SaveDir,Num); 
    end
end
fprintf("所有Benchmark2testFuDiySize已制作完成！\n");

Num = 100;   % 设置新的边长尺寸  256 16*7=112可以用7张
SensorNames = {'GF1' }; %{'GF1','IK','QB','WV2','WV3','WV4'} {'GF1','GF2','JL1','QB','WV2','WV3'}  'GF1','GF2','IK','JL1','QB','WV2','WV3','WV4'
for i = 1:numel(SensorNames)
    Sensor_Data = strcat(SensorNames{i}, '_Data');    % 或者    Sensor_Data = SensorNames{i} + "_Data";    
    for panSize = [256,128,64,32]    %[256,128,64,32]
        PathDir=fullfile('F:\Demo\Data_Dataset',Sensor_Data,'Benchmark'); %准备制作成测试集的Benchmark文件放入该目录
        SaveDir=fullfile('F:\Demo\Data_Dataset',Sensor_Data); %设置自定义目录为新一级目录
        Benchmark2TestDRDiySize (PathDir, panSize, SaveDir,Num); 
    end
end

fprintf("所有Benchmark2testDRDiySize已制作完成，该环节脚本程序结束！\n");



%% 4.3 融合后数据集转换
% 针对Tif格式的融合结果 转为Mat格式，方便后续流程

clc;clear;close all;addpath(genpath('.\Fx\'));


SensorName = 'QB';
FusionImgYijiPath ='';
saveDir = '';%设置对应保存路径
TifOutputYijiDir2Mat (FusionImgYijiPath,saveDir,SensorName) % 转换图像在一级目录下使用
SensorName = 'QB';
FusionImgYijiPath ='';
saveDir = '';%设置对应保存路径
TifOutputErjiDir2Mat (FusionImgYijiPath,saveDir,SensorName) % 转换图像在二级目录下使用

fprintf("所有数据集转换 完成，该环节脚本程序结束！\n");



