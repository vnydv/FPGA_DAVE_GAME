import os

sprite_raw_data_folder = "sprites_raw_data"
sprite_bit_data_folder = "sprites_colourbits"

# pixel app format is aaBBGGRR (a-> alpha channel)
# target format is BGR
# extract that way only
srcPath = os.getcwd()+"\\sprite_bitstream_generator\\"+sprite_raw_data_folder
destPath = os.getcwd()+"\\sprite_bitstream_generator\\"+sprite_bit_data_folder

file_names = os.listdir(srcPath)

for _fname in file_names:
    fname = f"{srcPath}\\{_fname}"
    print("Processing:", _fname, end='...')

    file_data_converted = []
    with open(fname, 'r') as dfile:
        data = dfile.readlines()[10:]
        # all are 16x16
        # get to line number 11
        for dline in data:
            if "}" in dline: break
            #print(dline)
            for abgr in dline.split(','):
                if not "x" in abgr: break
                bgr = abgr.strip()[4:]
                #print(abgr, bgr)
                b,g,r = bgr[0], bgr[2], bgr[4]
                b = (bin(int(b, 16))[2:]).zfill(4)
                g = (bin(int(g, 16))[2:]).zfill(4)
                r = (bin(int(r, 16))[2:]).zfill(4)

                # to 16 bit val
                rgb = f"{r}{g}{b}0000"

                file_data_converted.append(rgb+'\n')

    # save the output
    bfileName = f"{destPath}\\{_fname[:-2]}.bin"
    with open(bfileName, 'w') as bfile:
        bfile.writelines(file_data_converted)

    print("_/")
