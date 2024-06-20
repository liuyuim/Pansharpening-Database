import gdal
import os
import glob
import numpy as np
from tqdm import tqdm
import cv2


def read_tiff(input_file):
    """
    读取TIFF格式的遥感影像文件
    :param input_file:输入影像
    :return:波段数据，仿射变换参数，投影信息、行数、列数、波段数
    """
    # 使用gdal库打开影像文件，然后获取影像的行数、列数、仿射变换参数和投影信息等信息。
    dataset = gdal.Open(input_file) 
    rows = dataset.RasterYSize # 影像行数
    cols = dataset.RasterXSize  # 影像列数

    geo = dataset.GetGeoTransform()  # 仿射变换参数
    proj = dataset.GetProjection()  # 投影信息

    couts = dataset.RasterCount  # 波段数
    array_data = dataset.ReadAsArray() # 波段数据的数组 数组数据

    return array_data, geo, proj, rows, cols, couts

def write_tiff(output_file, array_data, rows, cols, counts, geo, proj):
    """
    将数组数据写入TIFF文件
    :param output_file: 输出文件路径
    :param array_data: 数组数据
    :param rows: 行数
    :param cols: 列数
    :param counts: 波段数
    :param geo: 仿射变换参数
    :param proj: 投影信息
    :return: None
    """
    # 根据数组数据的数据类型确定影像的数据类型
    # 判断栅格数据的数据类型
    if 'int8' in array_data.dtype.name:
        datatype = gdal.GDT_Byte
    elif 'int16' in array_data.dtype.name:
        datatype = gdal.GDT_UInt16
    else:
        datatype = gdal.GDT_Float32

    # 创建TIFF文件
    Driver = gdal.GetDriverByName("GTiff")
    dataset = Driver.Create(output_file, cols, rows, counts, datatype)

    dataset.SetGeoTransform(geo)  # 设置仿射变换参数
    dataset.SetProjection(proj)  # 设置投影信息

    # 将数组数据写入TIFF文件
    if len(array_data.shape) == 2:
        array_data = array_data.reshape(1, array_data.shape[0], array_data.shape[1])
    for i in range(counts):
        band = dataset.GetRasterBand(i + 1)
        band.WriteArray(array_data[i, :, :])


def pixel2world(geo, x, y):
    """
    将像素坐标转换为地理坐标
    :param geo: 仿射变换参数
    :param x: 像素横坐标
    :param y: 像素纵坐标
    :return: 地理坐标X  地理坐标Y
    """    
    Xgeo = geo[0] + x * geo[1] + y * geo[2]
    Ygeo = geo[3] + x * geo[4] + y * geo[5]
    return Xgeo, Ygeo


def world2Pixel(geoMatrix, x, y):
    """
    将地理坐标转换为像素坐标
    :param geoMatrix: 仿射变换参数
    :param x: 地理坐标X
    :param y: 地理坐标Y
    :return: 像素横坐标，像素纵坐标
    """
    dTemp = geoMatrix[1] * geoMatrix[5] - geoMatrix[2] * geoMatrix[4]
    Xpixel = (geoMatrix[5] * (x - geoMatrix[0]) - geoMatrix[2] * (y - geoMatrix[3])) / dTemp + 0.5
    Yline = (geoMatrix[1] * (y - geoMatrix[3]) - geoMatrix[4] * (x - geoMatrix[0])) / dTemp + 0.5
    return int(Xpixel), int(Yline)


# 双线性插值
def bilinear_interpolation(src_image, scale):
    # 使用OpenCV的resize函数进行上采样
    # target_h, target_w = int(src_image.shape[1] * scale), int(src_image.shape[2] * scale)
    # result = cv2.resize(src_image, (target_w, target_h), interpolation=cv2.INTER_LINEAR)
    num_bands, src_h, src_w = src_image.shape
    target_h, target_w = int(src_h * scale), int(src_w * scale)

    result_list = []
    for band in range(num_bands):
        # 效果最好的是 cv.INTER_CUBIC (三次样条插值)（速度慢）或者 cv.INTER_LINEAR 双线性插值（速度快一些但结果仍然不错）。
        result_band = cv2.resize(src_image[band], (target_w, target_h), interpolation=cv2.INTER_LINEAR)
        result_list.append(result_band)
    
    result = np.stack(result_list, axis=0) 
    # result_list 是一个包含每个波段上采样结果的列表，每个波段都是一个二维数组。
    # 这些波段数组沿着轴0进行堆叠，形成一个新的 (4, target_h, target_w) 数组。
    return result


def crop_image(input_data_path, clip_size, scale, align_by_geo):
    """
    裁剪影像并保存
    :param input_data_path: 输入数据文件夹路径
    :param clip_size: 裁剪大小
    :param scale: 上采样比例
    :param align_by_geo: 是否根据地理坐标对齐
    :return: None
    """
    # 获取多光谱和全色影像的文件路径
    input_ms_path = glob.glob(os.path.join(input_data_path, "ms", "*.TIF"))
    # input_msup_path = glob.glob(os.path.join(input_data_path, "ms_up", "*.TIF"))
    input_pan_path = glob.glob(os.path.join(input_data_path, "pan", "*.TIF"))

    # 创建保存裁剪影像的文件夹output_path
    # output_path = os.path.join(input_data_path, 'cropped_images')
    # if not os.path.exists(output_path):
    #     os.makedirs(output_path)
    output_path_ms = os.path.join(input_data_path, 'TifClip_MS')
    if not os.path.exists(output_path_ms):
        os.makedirs(output_path_ms)
    output_path_pan = os.path.join(input_data_path, 'TifClip_Pan')
    if not os.path.exists(output_path_pan):
        os.makedirs(output_path_pan)
    output_path_msup = os.path.join(input_data_path, 'TifClip_MSUp')
    if not os.path.exists(output_path_msup):
        os.makedirs(output_path_msup)
    output_path_ms1b_list = ['TifClip_MS1','TifClip_MS2','TifClip_MS3','TifClip_MS4']
    output_path_msup1b_list = ['TifClip_MSUp1','TifClip_MSUp2','TifClip_MSUp3','TifClip_MSUp4']
    

    # 遍历每一对多光谱和全色影像，
    for i, ms_path in enumerate(tqdm(input_ms_path)):
        lr_array_data, lr_geo, lr_proj, lr_rows, lr_cols, lr_couts = read_tiff(ms_path)
        array_data, geo, proj, rows, cols, couts = read_tiff(input_pan_path[i])

        # 计算裁剪次数j_iters和k_iters
        j_iters = lr_rows // (clip_size // scale)
        k_iters = lr_cols // (clip_size // scale)

        data_index = 1  # 计数器，用于给裁剪块编号

        for j in range(j_iters):
            for k in range(k_iters):
                # 根据裁剪大小和上采样比例计算裁剪范围
                size = clip_size // scale
                h_s = j * size
                h_e = h_s + size
                w_s = k * size
                w_e = w_s + size
                # ms_data = lr_array_data[:, h_s:h_e, w_s:w_e].astype(np.uint16)
                ms_data = lr_array_data[:, h_s:h_e, w_s:w_e].astype(np.uint8)                  
                ms_data_upsampled = bilinear_interpolation(ms_data, scale)

                if align_by_geo:
                    # 如果选择根据地理坐标对齐，就将裁剪块的像素坐标转换为地理坐标
                    x, y = pixel2world(lr_geo, w_s, h_s)
                    lr_b_geo = list(lr_geo)
                    lr_b_geo[0] = x
                    lr_b_geo[3] = y

                    # 根据地理坐标在全色影像中找到对应的裁剪块
                    (m_y, m_x) = world2Pixel(geo, x, y) # x is lon, y is lat, but out is (col, row)
                    b_geo = list(geo)
                    b_geo[0] = x
                    b_geo[3] = y

                    # 获取裁剪块的数据
                    # pan_data = array_data[:, (m_x):(m_x) + clip_size, (m_y):(m_y) + clip_size]
                    pan_data = array_data[ (m_x):(m_x) + clip_size, (m_y):(m_y) + clip_size]
                else:
                    pan_data = array_data[:, h_s * scale:h_e * scale, w_s * scale:w_e * scale]
                    lr_b_geo = list(lr_geo)
                    b_geo = list(geo)

                # 条件判断的目的是确保裁剪得到的影像块包含足够的有效信息，避免保存一些完全无效或空白的影像块。
                if np.sum(ms_data != 0) >= int(ms_data.shape[0] * ms_data.shape[1] * ms_data.shape[2]):
                # 将裁剪得到的多光谱、全色和上采样多光谱影像保存到不同的文件中，并为每个裁剪块添加唯一的编号。
                    # save_lr_batch_path = os.path.join(output_path, f'{i}_lr_{data_index}.tif')
                    # save_hr_batch_path = os.path.join(output_path, f'{i}_hr_{data_index}.tif')
                    # save_up_batch_path = os.path.join(output_path, f'{i}_up_{data_index}.tif')
                    save_lr_batch_path = os.path.join(output_path_ms, f'MS_{data_index}.tif')
                    save_hr_batch_path = os.path.join(output_path_pan, f'Pan_{data_index}.tif')
                    save_up_batch_path = os.path.join(output_path_msup, f'MSUp_{data_index}.tif')

                    write_tiff(save_lr_batch_path, ms_data, size, size, lr_couts, tuple(lr_b_geo), lr_proj)
                    write_tiff(save_hr_batch_path, pan_data, clip_size, clip_size, couts, tuple(b_geo), proj)
                    write_tiff(save_up_batch_path, ms_data_upsampled, clip_size, clip_size, lr_couts,tuple(lr_b_geo), lr_proj)

                    # 单独输出每个波段的多光谱影像
                    for band_index in range(lr_couts):
                        output_path_ms1b = output_path_ms1b_list[band_index]
                        output_path_ms1b = os.path.join(input_data_path, output_path_ms1b)
                        if not os.path.exists(output_path_ms1b):
                            os.makedirs(output_path_ms1b)
                        single_band_lr = ms_data[band_index, :, :]
                        single_band_lr_path = os.path.join(output_path_ms1b, f'MSband{band_index + 1}_{data_index}.tif')
                        write_tiff(single_band_lr_path, single_band_lr, size, size, 1, tuple(lr_b_geo), lr_proj)

                    # 单独输出每个波段的上采样多光谱影像
                    for band_index in range(lr_couts):
                        output_path_msup1b = output_path_msup1b_list[band_index]
                        output_path_msup1b = os.path.join(input_data_path, output_path_msup1b)
                        if not os.path.exists(output_path_msup1b):
                            os.makedirs(output_path_msup1b)
                        single_band_up = ms_data_upsampled[band_index, :, :]
                        single_band_up_path = os.path.join(output_path_msup1b, f'MSUpband{band_index + 1}_{data_index}.tif')
                        write_tiff(single_band_up_path, single_band_up, clip_size, clip_size, 1, tuple(lr_b_geo), lr_proj)


                    data_index += 1

# 参数设置
clip_size = 1024  # 裁切大小
scale = 4  # 上采样比例
align_by_geo = True  # 是否根据地理坐标对齐

# 文件夹路径
# input_data_path = r'F:\AFusionGroup\DataBase\GF1\Scene2_Batch2_EntireTif_Unit8_GF1B_PMS_E101.1_N22.4_20190221_L1A1227594242'
# crop_image(input_data_path, clip_size, scale, align_by_geo)

# input_data_path = r'F:\AFusionGroup\DataBase\GF2\Scene2_Batch2_EntireTif_Unit8_GF2_PMS1_E100.7_N22.3_20190412_L1A0003936529'
# crop_image(input_data_path, clip_size, scale, align_by_geo)

# input_data_path = r'F:\AFusionGroup\DataBase\QB\Scene3_Batch2_EntireTif_Unit8_005529043020_01'
# crop_image(input_data_path, clip_size, scale, align_by_geo)

# input_data_path = r'F:\AFusionGroup\DataBase\QB\Scene4_Batch2_EntireTif_Unit8_005761847030_01'
# crop_image(input_data_path, clip_size, scale, align_by_geo)

# input_data_path = r'F:\AFusionGroup\DataBase\WV2\Scene3_Batch2_EntireTif_Unit8_Stockholm_Map-Ready_Ortho_40cm_055674140050_01'
# crop_image(input_data_path, clip_size, scale, align_by_geo)

# input_data_path = r'F:\AFusionGroup\DataBase\WV2\Scene4_Batch2_EntireTif_Unit8_WashingtonDC_Map-Ready_Ortho_40cm_055675869020_01'
# crop_image(input_data_path, clip_size, scale, align_by_geo)

# input_data_path = r'F:\AFusionGroup\DataBase\WV3\Scene3_Batch2_EntireTif_Unit8_Rio_Map-Ready_Ortho_30cm_055670633050_01'
# crop_image(input_data_path, clip_size, scale, align_by_geo)

# input_data_path = r'F:\AFusionGroup\DataBase\WV3\Scene4_Batch2_EntireTif_Unit8_Tripoli_Map-Ready_Ortho_30cm_055675519050_01'
# crop_image(input_data_path, clip_size, scale, align_by_geo)

input_data_path = r'F:\AFusionGroup\DataBase\JL1\Scene1_Batch1_01'
crop_image(input_data_path, clip_size, scale, align_by_geo)