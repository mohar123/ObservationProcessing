program write_ro_hdr
!========================================
! write_ro_hdr:
! write NCEP bufr file header 
!
! History:
! Doug Hunt May, 2017    created.
! Hui Shao  July 26, 2017  Added comman line read for timestamp 
!
! Build:
! gfortran -o write_ro_hdr -ffree-form -ffree-line-length-none write_ro_hdr.f90 WRFDA/var/external/bufr/libbufr.a
!========================================

   implicit none
   character(len=8)     :: subset
   integer, parameter   :: n1ahdr  = 15
   integer              :: iunit_bufr,iret,iunit_dx,ldate
   character(len=256)   :: bufr_out_fname
   integer              :: idate6(6) !yy,mm,dd,hh,mi,ss

   integer              :: n_arguments   ! # of command line argument
   integer              :: iargc         ! function declaration
   character(len=256)   :: timestamp
   character(len=13)    :: timestamps


  !---- get time stamp from command line
  n_arguments = iargc()
  if (n_arguments .eq. 1) then
      call getarg(1, timestamp)
      timestamps = trim(timestamp)
     print*, 'timestamp =', timestamps
  else
      write(*,*) 'write_ro_hdr yyyy.mm.dd.hh'
      stop
  endif

   read(timestamps(1:4), '(i)') idate6(1)
   read(timestamps(6:7), '(i)') idate6(2)
   read(timestamps(9:10), '(i)') idate6(3)
   read(timestamps(12:13), '(i)') idate6(4)

   ldate = idate6(1)*1000000 + &
           idate6(2)*10000 +   &
           idate6(3)*100 +     &
           idate6(4)
   print *, 'ldate = ', ldate

   bufr_out_fname = 'gpsro_hdr.bufr'
   subset = 'NC003010'
   iunit_bufr = 50
   iunit_dx = 51

   open(iunit_bufr,file=trim(bufr_out_fname),iostat=iret,form='unformatted',status='unknown')
   if ( iret /= 0 ) then
      write(0,*) 'error opening file ', trim(bufr_out_fname)
      stop
   end if
   open(iunit_dx,file='bufrtab_NC003010_gpsro.txt',iostat=iret,form='formatted',status='old')
   if ( iret /= 0 ) then
      write(0,*) 'error opening bufr table'
      stop
   end if

   call openbf(iunit_bufr,'OUT',iunit_dx)

   call openmb(iunit_bufr,subset,ldate)

   call writsb(iunit_bufr)

   call closbf(iunit_bufr)
   close(iunit_bufr)
   close(iunit_dx)

end program write_ro_hdr
