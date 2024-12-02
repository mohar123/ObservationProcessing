#
##  Copyright (c) 1995-2017 University Corporation for Atmospheric Research
## All rights reserved
#
#/**----------------------------------------------------------------------
# @file       TimeClass.py
#
# Class for dealing with GPS times in various representations
#
# @author     Chris Bogart, Doug Hunt
# @since      08/29/96
# @version    $URL$ $Id$
# @example    from TimeClass import *
# @           tc = TimeClass().set_yrdoy_gps('2004.004')
# @           gps = tc.get_gps()
# @           year, month, day, hour, minute, second = tc.get_ymdhms_gps()
# -----------------------------------------------------------------------*/

import calendar
import time
import re

class TimeClass:

  # Number of seconds between unix time base (1970)
  # and gps time base (jan 6, 1980).  This neglects
  # the growing leap second offset (now 11 seconds)
  GPSSEC = 315964800

  # Default to Jan 6, 1980 0Z
  def __init__(self):
    self.gpssec = 0

  #/**----------------------------------------------------------------------
  # @sub  find_month_days
  #
  # Given an input year, compute an array of days in each month (1-based)
  #
  # @parameter  year
  # @return     Array ref: 1-based array of days in each month, 1-12
  # ----------------------------------------------------------------------*/
  def find_month_days(self, yr):

    feb = 28
    if (yr % 4   == 0):
      feb = 29
    if (yr % 100 == 0):
      feb = 28
    if (yr % 400 == 0):
      feb = 29
    months = [0, 31, feb, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    return months

  #/**----------------------------------------------------------------------    
  # @sub  find_date
  #
  # convert year, doy to month and date
  #
  # @parameter  year
  # @           doy
  # @return     month, day
  # ----------------------------------------------------------------------*/
  def find_date(self, yr, doy):

    month_days = self.find_month_days(yr)

    for i in range(1,13): # This means (1..12) (odd..)
      if doy <= month_days[i]: break
      doy -= month_days[i]

    month = i
    return month, doy

  #/**----------------------------------------------------------------------    
  # @sub  set_gps
  # 
  # Set GPS time
  # 
  # @parameter  self     a TimeClass object
  # @           integer GPS seconds since Jan 6, 1980 at 0Z
  # @return     self
  # ----------------------------------------------------------------------*/
  def set_gps(self, gpssec):
    self.gpssec = gpssec
    return self

  #/**----------------------------------------------------------------------    
  # @sub  set_yrdoy_gps
  # 
  # Set GPS time from 'YYYY.DDD'
  # 
  # @parameter  self     a TimeClass object
  # @           string:  'YYYY.DDD'
  # @return     self
  # ----------------------------------------------------------------------*/
  def set_yrdoy_gps(self, yrdoy):
    yr, doy = yrdoy.split('.')
    yr, doy = int(yr), int(doy)
    mo, mday = self.find_date(yr, doy)
    self.gpssec = calendar.timegm([yr,mo,mday,0,0,0]) - TimeClass.GPSSEC
    return self

  #/**----------------------------------------------------------------------    
  # @sub  set_yrdoyhms_gps
  # 
  # Set GPS time from yr, doy, hr, min, sec
  # 
  # @parameter  self     a TimeClass object
  # @           year, day of year, hour, minute and second (need not be an integer)
  # @return     self
  # ----------------------------------------------------------------------*/
  def set_yrdoyhms_gps(self, yr, doy, hr, min, sec):
    mo, mday = self.find_date(yr, doy)
    self.gpssec = calendar.timegm([yr,mo,mday,hr,min,sec]) - TimeClass.GPSSEC
    return self

  #/**----------------------------------------------------------------------    
  # @sub       get_gps
  # 
  # Return gps seconds from object
  # 
  # @parameter  self     a TimeClass object
  # @return     gps seconds since 1/6/1980
  # ----------------------------------------------------------------------*/
  def get_gps(self):
    return self.gpssec

  #/**----------------------------------------------------------------------    
  # @sub       get_yrdoyhms_gps
  # 
  # Return GPS yr, doy, hour, minute, second
  # 
  # @parameter  self     a TimeClass object
  # @return     yr, doy, hour, minute, second
  # ----------------------------------------------------------------------*/
  def get_yrdoyhms_gps(self):
    frac = self.gpssec - int(self.gpssec)
    tm = time.gmtime(self.gpssec + TimeClass.GPSSEC)
    return [tm.tm_year, tm.tm_yday, tm.tm_hour, tm.tm_min, tm.tm_sec + frac]

  #/**----------------------------------------------------------------------    
  # @sub  get_ymdhms_gps
  #
  # Get GPS time broken down
  #
  # @parameter  self     a TimeClass object
  # @return     gps year, month, day, hour, minute and second 
  # ----------------------------------------------------------------------*/
  def get_ymdhms_gps(self):
    frac = self.gpssec - int(self.gpssec)
    tm = time.gmtime(self.gpssec + TimeClass.GPSSEC)
    return [tm.tm_year, tm.tm_mon, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec + frac]

  #/**----------------------------------------------------------------------    
  # @sub  get_yrdoy_gps
  # 
  # Get GPS time in 'YYYY.DDD' format
  # 
  # @parameter  self     a TimeClass object
  # @return     YYYY.DDD
  # ----------------------------------------------------------------------*/
  def get_yrdoy_gps(self):
    frac = self.gpssec - int(self.gpssec)
    tm = time.gmtime(self.gpssec + TimeClass.GPSSEC)
    return "%04d.%03d" % (tm.tm_year, tm.tm_yday)

  #/**----------------------------------------------------------------------    
  # @sub   inc_sec_gps
  # 
  # Increment seconds in gps time
  # 
  # @parameter  self     a TimeClass object
  # @           increment in seconds, default = 1
  # @return     self     Timeclass object with several seconds later time
  # ----------------------------------------------------------------------*/
  def inc_sec_gps(self, sec):
    self.gpssec += sec
    return self


class TimeRange:

  #/**----------------------------------------------------------------------    
  # @sub       set_daterange
  # 
  # Create a new TimeClass object with a date range in it.
  # This creates a TimeClass object with start and end times in it as
  # well.
  # 
  # @parameter  self     a TimeClass object
  # @           daterange:  YYYY.DDD or YYYY.DDD-DDD or YYYY.DDD-YYYY.DDD or 
  #                         YYYY.DDD,YYYY.DDD-DDD,YYYY.DDD-YYYY.DDD
  # @return     self     a TimeClass object
  # ----------------------------------------------------------------------*/
  def set_daterange(self, daterange):

    sections = daterange.split(',')
    self.startgps = []
    self.endgps   = []

    for range in sections:

      #print(re.split(r'[.-]', str(2022.302)))
      #parts = [int('x') for x in re.split(r'[.-]', str(range))] # parts now integers
      parts = [x for x in re.split(r'[.-]', str(range))] # parts now integers
      print(parts)
      tc = TimeClass()
      if len(parts) == 2:    # YYYY.DDD
        self.startgps.append(tc.set_yrdoy_gps(range).get_gps())
        self.endgps.append(tc.set_yrdoy_gps(range).get_gps())
      elif len(parts) == 3:  # YYYY.DDD-DDD
        start = "%04d.%03d" % (parts[0], parts[1])
        end   = "%04d.%03d" % (parts[0], parts[2])
        self.startgps.append(tc.set_yrdoy_gps(start).get_gps())
        self.endgps.append(tc.set_yrdoy_gps(end).get_gps())
      elif len(parts) == 4:     # YYYY.DDD-YYYY.DDD
        start = "%04d.%03d" % (parts[0], parts[1])
        end   = "%04d.%03d" % (parts[2], parts[3])
        self.startgps.append(tc.set_yrdoy_gps(start).get_gps())
        self.endgps.append(tc.set_yrdoy_gps(end).get_gps())

    self.gps = self.startgps[0]  # earliest time.
    return self


  #/**----------------------------------------------------------------------    
  # @sub       get_dates
  # 
  # Retrieve a list of YYYY.DDD strings from the input TimeRange object, 
  # Based on the input increment in days (default = 1 day).
  # 
  # @parameter  self     a TimeRange object
  # @           inc      optional:  time increment.  Defaults to one day.
  # @return     self     a TimeRange object
  # ----------------------------------------------------------------------*/
  def get_dates(self):
    dates = []
    tc = TimeClass()

    for i in range(len(self.startgps)):
      time = self.startgps[i]
      end  = self.endgps[i]

      while True:
        if time > end: break
        dates.append(tc.set_gps(time).get_yrdoy_gps())
        time += 86400

    return dates


