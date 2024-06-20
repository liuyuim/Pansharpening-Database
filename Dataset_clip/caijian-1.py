##单波段
from PIL import Image
import os
Image.MAX_IMAGE_PIXELS = None

# 定义输入文件夹和输出文件夹
# input_folder = 'F:\AFusionGroup\DataBase\JL1\Scene1_Batch1_EntireTif_JL1GF02A_PMS1_20211120110401_200067242_102_0013_001_L1\ms'
input_folder = 'F:\AFusionGroup\DataBase\JL1\Scene1_Batch1_EntireTif_JL1GF02A_PMS1_20211120110401_200067242_102_0013_001_L1\pan'
# output_folder = 'F:\AFusionGroup\DataBase\JL1\Scene1_Batch1_EntireTif_JL1GF02A_PMS1_20211120110401_200067242_102_0013_001_L1\ClipMS'
output_folder = 'F:\AFusionGroup\DataBase\JL1\Scene1_Batch1_EntireTif_JL1GF02A_PMS1_20211120110401_200067242_102_0013_001_L1\ClipPan'

# 确保输出文件夹存在
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# 定义裁剪尺寸
# crop_size = (256, 256)
crop_size = (1024, 1024)

# 遍历输入文件夹中的所有图像文件
for filename in os.listdir(input_folder):
    if filename.endswith('.tif') or filename.endswith('.jpg'):
        # 打开图像文件
        img = Image.open(os.path.join(input_folder, filename))
        # img = img.convert('RGB')
        # 获取图像的宽度和高度
        width, height = img.size

        # 计算水平和垂直裁剪的次数
        horizontal_cuts = width // crop_size[0]
        vertical_cuts = height // crop_size[1]

        k = 1

        # 执行裁剪和保存
        for i in range(horizontal_cuts):
            for j in range(vertical_cuts):
                left = i * crop_size[0]
                upper = j * crop_size[1]
                right = left + crop_size[0]
                lower = upper + crop_size[1]

                # 裁剪图像
                cropped_img = img.crop((left, upper, right, lower))

                # 构造输出文件名
                # output_filename = f"{filename.split('.')[0]}_{i}_{j}.tif"
                output_filename = f"{filename.split('.')[0]}_{k}.tif"
                k = k+1

                # 保存裁剪后的图像
                cropped_img.save(os.path.join(output_folder, output_filename))

        # 关闭原始图像文件
        img.close()

