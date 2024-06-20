import os
import shutil

def process_folder(folder_path):
    # 获取文件夹中的所有文件
    file_list = sorted(os.listdir(folder_path))

    # 每隔 5个文件取一个，并重命名为连续的数字
    new_file_list = []
    for idx, filename in enumerate(file_list):
        if idx % 5 == 0:
            new_idx = len(new_file_list) + 1
            new_filename = f"{new_idx:04d}{os.path.splitext(filename)[1]}" # 获取文件的扩展名，用于保留原始文件的类型
            new_file_list.append((filename, new_filename))
    
    # 移动并重命名文件
    for old_filename, new_filename in new_file_list:
        old_path = os.path.join(folder_path, old_filename)
        new_path = os.path.join(folder_path, new_filename)
        shutil.move(old_path, new_path)

    # 删除剩余的文件
    files_to_keep = [new_filename for _, new_filename in new_file_list]
    # 这是一个列表解析，它遍历了 new_file_list 中的元组，提取出每个元组的第二个元素（新文件名），并赋值给 new_filename
    # 并将它们放入一个新的列表中，即 files_to_keep。这个列表包含了需要保留的文件名。
    for filename in file_list:
        if filename not in files_to_keep:
            file_path = os.path.join(folder_path, filename)
            if os.path.isfile(file_path):
                os.remove(file_path)

    # 将四位数字编号改回自然数编号
    new_files = sorted([new_filename for _, new_filename in new_file_list])
    for idx, new_filename in enumerate(new_files, start=1):
        new_path = os.path.join(folder_path, new_filename)
        natural_filename = f"{idx}{os.path.splitext(new_filename)[1]}"
        natural_path = os.path.join(folder_path, natural_filename)
        os.rename(new_path, natural_path)
    
def main(root_dir):
    # 查找以 "TifClip_" 开头的子文件夹
    for item in os.listdir(root_dir):
        item_path = os.path.join(root_dir, item)
        if os.path.isdir(item_path) and item.startswith("TifClip_"):
            print(f"Processing folder: {item}")
            process_folder(item_path)

if __name__ == "__main__":
    root_dir = r'F:\AFusionGroup\DataBase\GF1\Scene2_Batch2_EntireTif_Unit8_GF1B_PMS_E101.1_N22.4_20190221_L1A1227594242'
    main(root_dir)
