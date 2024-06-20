from osgeo import gdal
import os

# 输入遥感影像文件路径
# input_image_path = 'C:/Users/TQW/Desktop/ms/MS.tif'       
# Pan
# input_image_path = 'F:\AFusionGroup\DataBase\JL1\Scene1_Batch1_EntireTif_JL1GF02A_PMS1_20211120110401_200067242_102_0013_001_L1\pan\Pan.tif'
# output_image_path = 'F:\AFusionGroup\DataBase\JL1\Scene1_Batch1_EntireTif_JL1GF02A_PMS1_20211120110401_200067242_102_0013_001_L1\ClipPan'
# cut_size = 1024
# MS
input_image_path = 'F:\AFusionGroup\DataBase\JL1\Scene1_Batch1_EntireTif_JL1GF02A_PMS1_20211120110401_200067242_102_0013_001_L1\ms\MS.tif'
output_image_path = 'F:\AFusionGroup\DataBase\JL1\Scene1_Batch1_EntireTif_JL1GF02A_PMS1_20211120110401_200067242_102_0013_001_L1\ClipMS'
cut_size = 256

# 打开遥感影像
ds = gdal.Open(input_image_path)

if ds is None:
    print(f"无法打开文件：{input_image_path}")
    exit(1)

width = ds.RasterXSize
height = ds.RasterYSize

# 指定剪切框大小
# cut_size = 256

k = 1
# 循环遍历并剪切图像
for i in range(0, width, cut_size):
    for j in range(0, height, cut_size):
        # 计算剪切窗口的坐标
        x_offset = i
        y_offset = j
        x_size = min(cut_size, width - x_offset)
        y_size = min(cut_size, height - y_offset)

        # 检查是否可以产生256x256的图像
        if x_size >= cut_size and y_size >= cut_size:
            # 创建输出文件名
            # output_filename = f"cut_{x_offset}_{y_offset}.tif"
            output_filename = f"{k}.tif"
            k = k+1
            # output_path = os.path.join('C:/Users/TQW/Desktop/output', output_filename)
            output_path = os.path.join(output_image_path, output_filename)

            # 剪切并保存图像
            gdal.Translate(output_path, ds, srcWin=(x_offset, y_offset, x_size, y_size))

print("剪切和保存完成")


# 关闭遥感影像数据集
ds = None



