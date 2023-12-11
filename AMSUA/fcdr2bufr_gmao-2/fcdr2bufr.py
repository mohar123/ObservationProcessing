#!/home/imoradi/packages/anaconda3/bin/python3

#  This code mainly lists the files and match the filenames for window 
# and sounding channels then runs the fortran code to generate the bufr files
#
# Isaac Moradi Isaac.Moradi@nasa.gov
# June 2017

import sys, getopt
from datetime import datetime, timedelta
import numpy as np
import os
import glob
import subprocess
import pdb

def list_files(path, pattern):
     import os
     from glob import glob
     flist = []
     for dir,_,_ in os.walk(path):  
        print(dir)
        files = glob(os.path.join(dir,pattern))

        for f1 in files:
            print(f1)
            if (not os.path.isfile(f1)):
               print("File does not exist")
               continue
            else:
               flist.append(f1)

     return sorted(flist)


def main(argv):
   #exename = '/gpfsm/dnb31/imoradi/fcdr2bfr_gmao/fcdr2bufr.exe'
   exename = '/discover/nobackup/projects/gmao/obsdev/mchattop/AMSUA1C/fcdr2bfr_gmao-1/fcdr2bufr.exe'

   start_month = ''
   end_month  = ''
   sensor = 'amsua'
   date1 = argv[1]
   print(['date:', date1])
   #data_dir='/data/users/imoradi/AMSUA_RECAL/fcdr'
   #data_out='/data/users/imoradi/data/cdr/bufr_new/uncorrected'
   data_dir='/discover/nobackup/projects/gmao/obsdev/mchattop/AMSUA1C/example_data_airsamsua'
   data_out='/discover/nobackup/projects/gmao/obsdev/mchattop/AMSUA1C/example_data_airsamsua/tmp'

   #listsat=["noaa-15", "noaa-16", "noaa-17", "noaa-18","metop-a"]
   listsat=["noaa-15","noaa-16","noaa-18","metop-a"]
   #listsat = ['aqua'] 
   date1 = datetime.strptime(date1, "%Y%m%d%H")

   if not os.path.exists(data_out): 
        os.makedirs(data_out)    

   for sat in listsat:
       sensor_sat='%s_%s'%(sensor, sat.replace("noaa-", "n"))
       #sensor_sat='%s'%(sensor, sat.replace("M02", "metop-a"))
       if 'aqua' in sat:
          #AIRS.20020701_S0805_E1005.nc
          fname="AIRS.%s*.nc"%(date1.strftime("%Y%m%d"))
       else:
          # CICS_V00R01_AMSUA_FCDR_N18_D16122_S125802_E143138_B5641516.nc
          fname="CICS*_D%s*.nc"%(date1.strftime("%y%j"))
          #fname="NESDIS*_D%s*.nc"%(date1.strftime("%Y%m%d"))  

       # find all the files within the specific hour
       print("%s/%s/%d"%(data_dir, sat, date1.year), fname)
       files = list_files("%s/%s/%d"%(data_dir, sat, date1.year), fname)
       print(files)
       files1 = []
       # NESDIS-STAR_FCDR_AMSU-A_V01R00_N18_D20160501_S1258_E1431.nc      
       for f in files:
           if 'AIRS' in f:
              f1 = f.replace('AIRS.', 'NESDIS-STAR_FCDR_AMSU-A_V01R00_AQUA_D')
              # The following line is just to help to read channel 14 from FCDR and all 
              # other from level 1b
              #f1 = f1.replace('/l1b/', '/fcdr/')
           else:
              f1 = f.replace('CICS_V00R01_AMSUA_FCDR', 'NESDIS-STAR_FCDR_AMSU-A_V01R00')

              # the following two lines are simply for the name change in reprocessed level-1b 
              # This assures to read window channels from l1b then read NOAA Sounding channels
              # which include both level-1b and cdr data - in case we want to use only chan 14
              # from CDR and the rest level1b
              #f1 = f.replace('CICS_V01R01-preliminary_AMSUA_FCDR', 'NESDIS-STAR_FCDR_AMSU-A_V01R00')
              #f1 = f1.replace('/l1b/', '/fcdr/')
              #.................................................................................

              f1 = f1.replace(date1.strftime("%y%j"), date1.strftime("%Y%m%d"))                
              idx = f1.find('_S')
              f1 = f1.replace(f1[idx+4:idx+8], f1[idx+4:idx+6])
              idx = f1.find('_E')
              f1 = f1.replace(f1[idx+4:idx+8], f1[idx+4:idx+6])
              idx = f1.find('_B')
              f1 = f1.replace(f1[idx:idx+9], "")

           files1.append(f1)
       for fname, fname1 in zip(files, files1):
            print([fname, fname1])
            subprocess.call([exename, fname, fname1, data_out, sensor_sat])

if __name__ == "__main__":   
    main(sys.argv)
