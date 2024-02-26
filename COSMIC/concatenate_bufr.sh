#!/bin/csh -X

foreach yy (15)
  foreach mm (05)
   foreach dd (01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31)
    #foreach dd (01)
      foreach hh (00 06 12 18)
          cat ../GPS_noCOSMIC1/nocsmic_gdas1.${yy}${mm}${dd}.t${hh}z.gpsro.tm00.bufr_d ../BUFR_Cp/20${yy}/${mm}/bfrPrf_Cp_20${yy}${mm}${dd}.${hh}z.bufr > gdas1_new.${yy}${mm}${dd}.t${hh}z.gpsro.tm00.bufr_d
        end
      end
   end
end




exit

