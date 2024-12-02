#!/usr/bin/env python

"""cdaac2ncep.py

This script batches groups of single-profile WMO Radio Occultation BUFR files from
the UCAR/CDAAC data processing center (file type 'bfrPrf') into combined BUFR files
with NCEP flavor headers suitable for ingesting into the GSI.

Usage: cdaac2ncep.py YYYY.DDD interval_in_hours mission1,mission2,...
Example: ./cdaac2ncep.py 2016.209-210 6 cosmicrt,kompsat5rt

Author:    Doug Hunt
Since:     02/09/2017
Version:   $URL$ $Id$

"""

import os
import sys
import argparse
import re
import struct
from TimeClass import *
from glob import glob

#
## Handle command-line arguments
#
parser = argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter)

parser.add_argument('daterange', help="Year.Day of year -[[yr].doy] (eg 2001.001, or 2001.001-002, or 2001.365-2002.001.  Also 2001.001,2002.001-002)")
parser.add_argument('interval',  help="Batching interval in hours", type=int)
parser.add_argument('missions',  help="Comma delimited list of missions to include")

args  = parser.parse_args(sys.argv[1:])

dates = TimeRange().set_daterange(args.daterange).get_dates()

# Loop over missions
mission_list = args.missions.split(',')

times = list(range(0, 24, args.interval)) # list of time offsets:  eg 0Z, 6Z, 12Z, 18Z

for date in dates:

  # Compute previous day from input date
  datem1 = TimeClass().set_yrdoy_gps(date).inc_sec_gps(-86400).get_yrdoy_gps()

  for tcenter in times:
    
    # Call the NCEP library to generate a BUFR header with the correct time for this time offset
    (yr, mon, day) = TimeClass().set_yrdoy_gps(date).get_ymdhms_gps()[0:3]
    daystamp = "%04d.%02d.%02d.%02d" % (int(yr), int(mon), int(day), tcenter)
    os.system ('./write_ro_hdr '+daystamp)
    
    ncep_hdr = open('gpsro_hdr.bufr',mode='rb').read()
    if len(ncep_hdr) == 0:
      raise Exception('Cannot find NCEP BUFR header file gpsro_hdr.bufr')

    # Time of epoch in GPS seconds
    centertime = TimeClass().set_yrdoy_gps(date).get_gps() + tcenter*3600;

    # Open output file for this time offset and write NCEP header to it
    outfile = "%s_%s_%02dZ.bufr" % (args.missions, date, tcenter)

    outfh = open (outfile, 'wb')
    outfh.write (ncep_hdr)

    for mission in mission_list:

      # Sorted list of files from this mission for the previous day
      files = sorted(glob(mission+'/'+datem1+'/*'))

      #Hui: need comment the following line so that the script won't stop due to missing days 
      # if len(files) == 0: raise Exception('No files found for previous day: ', datem1)
      if len(files) == 0: print("No files found for previous day: ", datem1)

      # Sorted list files from yesterday and today
      files = files + sorted(glob(mission+'/'+date+'/*'))
      
      # Loop over individual WMO BUFR files
      # Mohar changes
      for f in files:
        
        (fyr, fdoy, fhr, fmin) = [int(i) for i in re.search(r'(\d\d\d\d)\.(\d\d\d)\.(\d\d)\.(\d\d)', f).groups()]
        tfile = TimeClass().set_yrdoyhms_gps(fyr, fdoy, fhr, fmin, 0).get_gps() # Time of occultation in GPS seconds

        # If this occultation within the epoch time window
        if abs(centertime - tfile) < (args.interval/2.0 * 3600):

          # Read in the BUFR file
          fh = open (f, 'rb')
          filetext = fh.read()
          fh.close()

          # Get rid of header and trailer, leave only BUFR...7777
          p = re.compile(b'(BUFR.*7777)',re.DOTALL)
          filetext = p.search(filetext).group()

          # Change section 1 subtype from '14' to '10', which is what NCEP likes
          edition = filetext[7]
          subtype_idx = 17 if (edition == 3) else 20
          filetext = filetext[0:subtype_idx] + struct.pack ('B', 10) + filetext[subtype_idx+1:]
          outfh.write(filetext + b"\0\0\0\0")

    outfh.close # one file per time step for all missions
    print("FILE CREATION: ", outfile)


