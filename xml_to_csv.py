import os
import glob
import pandas as pd
import xml.etree.ElementTree as ET
import argparse


def xml_to_csv(path, img_file_path):
    xml_list = []
    for xml_file in glob.glob(path + '/*.xml'):
        tree = ET.parse(xml_file)
        root = tree.getroot()
        for member in root.findall('object'):
            value = (img_file_path+root.find('filename').text,
                     int(root.find('size')[0].text),
                     int(root.find('size')[1].text),
                     member[0].text,
                     int(member[4][0].text),
                     int(member[4][1].text),
                     int(member[4][2].text),
                     int(member[4][3].text)
                     )
            xml_list.append(value)
    column_name = ['filename', 'width', 'height', 'class', 'xmin', 'ymin', 'xmax', 'ymax']
    xml_df = pd.DataFrame(xml_list, columns=column_name)
    return xml_df


def main():
    parser = argparse.ArgumentParser(description = 'process xmls to csv')
    parser.add_argument('-path_xml', type = str, help = 'path to xmls folder')
    parser.add_argument('-path_img', type = str, help = 'path to imgs folder')
    parser.add_argument('-output', type = str, help = 'output file name')
    args = parser.parse_args()



    image_path = os.path.join(os.getcwd(), args.path_xml)
    xml_df = xml_to_csv(image_path, args.path_img)
    xml_df.to_csv(args.output, index=None)
    print('Successfully converted xml to csv.')


main()
