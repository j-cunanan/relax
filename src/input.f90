!-----------------------------------------------------------------------
! Copyright 2007, 2008, 2009 Sylvain Barbot
!
! This file is part of RELAX
!
! RELAX is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! RELAX is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with RELAX.  If not, see <http://www.gnu.org/licenses/>.
!-----------------------------------------------------------------------

#include "include.f90"

MODULE input

  USE types

  IMPLICIT NONE

  REAL*8, PARAMETER :: DEG2RAD = 0.01745329251994329547437168059786927_8

CONTAINS

  !---------------------------------------------------------------------
  !> subroutine init
  !! reads simulation parameters from the standard input and initialize
  !! model parameters.
  !!
  !! INPUT:
  !! @param unit - the unit number used to read input data
  !!
  !! OUTPUT:
  !! @param in
  !---------------------------------------------------------------------
  SUBROUTINE init(in)
    USE export
    USE getopt_m
    USE elastic3d

    TYPE(SIMULATION_STRUCT), INTENT(OUT) :: in

    CHARACTER :: ch
    CHARACTER(256) :: dataline
    CHARACTER(256) :: rffilename,filename
#ifdef VTK
    CHARACTER(3) :: digit
    CHARACTER(4) :: digit4
#endif
    INTEGER :: iunit,noptions
!$  INTEGER :: omp_get_num_procs,omp_get_max_threads
    REAL*8 :: dummy,dum1,dum2
    REAL*8 :: minlength,minwidth
    TYPE(OPTION_S) :: opts(15)

    INTEGER :: k,iostatus,i,e

    ! parse the command line for options
    opts( 1)=OPTION_S("no-relax-output",.FALSE.,CHAR(21))
    opts( 2)=OPTION_S("no-txt-output",.FALSE.,CHAR(22))
    opts( 3)=OPTION_S("no-vtk-output",.FALSE.,CHAR(23))
    opts( 4)=OPTION_S("no-grd-output",.FALSE.,CHAR(24))
    opts( 5)=OPTION_S("no-xyz-output",.FALSE.,CHAR(25))
    opts( 6)=OPTION_S("no-stress-output",.FALSE.,CHAR(26))
    opts( 7)=OPTION_S("version",.FALSE.,CHAR(27))
    opts( 8)=OPTION_S("with-eigenstrain",.FALSE.,CHAR(28))
    opts( 9)=OPTION_S("with-stress-output",.FALSE.,CHAR(29))
    opts(10)=OPTION_S("with-vtk-output",.FALSE.,CHAR(30))
    opts(11)=OPTION_S("with-vtk-relax-output",.FALSE.,CHAR(31))
    opts(12)=OPTION_S("with-transient",.FALSE.,CHAR(32))
    opts(13)=OPTION_S("with-curvilinear",.FALSE.,CHAR(33))
    opts(14)=OPTION_S("dry-run",.FALSE.,CHAR(34))
    opts(15)=OPTION_S("help",.FALSE.,'h')

    noptions=0;
    DO
       ch=getopt("h",opts)
       SELECT CASE(ch)
       CASE(CHAR(0))
          EXIT
       CASE(CHAR(21))
          ! option no-relax-output
          in%isoutputrelax=.FALSE.
       CASE(CHAR(22))
          ! option no-txt-output
          in%isoutputtxt=.FALSE.
       CASE(CHAR(23))
          ! option no-vtk-output
          in%isoutputvtk=.FALSE.
       CASE(CHAR(24))
          ! option no-grd-output
          in%isoutputgrd=.FALSE.
       CASE(CHAR(25))
          ! option no-xyz-output
          in%isoutputxyz=.FALSE.
       CASE(CHAR(26))
          ! option no-stress-output
          in%isoutputstress=.FALSE.
       CASE(CHAR(27))
          ! option version
          in%isversion=.TRUE.
       CASE(CHAR(28))
          ! option with-eigenstrain
          in%iseigenstrain=.TRUE.
       CASE(CHAR(29))
          ! option with-stress-output
          in%isoutputstress=.TRUE.
       CASE(CHAR(30))
          ! option with-vtk-output
          in%isoutputvtk=.TRUE.
       CASE(CHAR(31))
          ! option with-vtk-relax-output
          in%isoutputvtkrelax=.TRUE.
       CASE(CHAR(32))
          ! option --with-transient 
          in%istransient=.TRUE.
       CASE(CHAR(33))
          ! option --curvilinear
          in%iscurvilinear=.TRUE.
       CASE(CHAR(34))
          ! option dry-run
          in%isdryrun=.TRUE.
       CASE('h')
          ! option help
          in%ishelp=.TRUE.
       CASE('?')
          WRITE_DEBUG_INFO
          in%ishelp=.TRUE.
          EXIT
       CASE DEFAULT
          WRITE (0,'("unhandled option ", a, " (this is a bug")') optopt
          WRITE_DEBUG_INFO
          STOP 3
       END SELECT
       noptions=noptions+1
    END DO

    IF (in%isversion) THEN
       PRINT '("relax version 1.0.7, compiled on ",a)', __DATE__
       PRINT '("")'
       RETURN
    END IF
    IF (in%ishelp) THEN
       PRINT '("usage:")'
       PRINT '("")'
       PRINT '("relax [-h] [--dry-run] [--help] [--no-grd-output] [--no-relax-output]")' 
       PRINT '("      [--no-stress-output] [--no-txt-output] [--no-vtk-output]")'
       PRINT '("      [--no-xyz-output] [--with-eigenstrain] [--with-vtk-output]")'
       PRINT '("      [--with-vtk-relax-output] [--with-transient]")'
       PRINT '("")'
       PRINT '("options:")'
       PRINT '("   -h                      prints this message and aborts calculation")'
       PRINT '("   --dry-run               abort calculation, only output geometry")'
       PRINT '("   --help                  prints this message and aborts calculation")'
       PRINT '("   --no-grd-output         cancel output in GMT grd binary format")'
       PRINT '("   --no-relax-output       cancel output of the postseismic contribution")'
       PRINT '("   --no-stress-output      cancel output of stress tensor in any format")'
       PRINT '("   --no-txt-output         cancel output in text format")'
       PRINT '("   --no-vtk-output         cancel output in Paraview VTK format")'
       PRINT '("   --no-xyz-output         cancel output in GMT xyz format")'
       PRINT '("   --version               print version number and exit")'
       PRINT '("   --with-eigenstrain      includes eigenstrain sources")'
       PRINT '("   --with-stress-output    export stress tensor")'
       PRINT '("   --with-vtk-output       export output in Paraview VTK format")'
       PRINT '("   --with-vtk-relax-output export relaxation to VTK format")'
       PRINT '("   --with-transient        include the transient rheology")'
       PRINT '("")'
       PRINT '("description:")'
       PRINT '("   Evaluates the deformation due to fault slip, surface loading")'
       PRINT '("   or inflation and the time series of postseismic relaxation")'
       PRINT '("   that follows due to fault creep or viscoelastic flow.")'
       PRINT '("")'
       PRINT '("see also: ""man relax""")'
       PRINT '("")'
       RETURN
    END IF
    PRINT 2000
    PRINT '("# RELAX: nonlinear postseismic relaxation with Fourier-domain Green''s function")'
#ifdef FFTW3
#ifdef FFTW3_THREADS
    PRINT '("#     * FFTW3 (multi-threaded) implementation of the FFT")'
#else
    PRINT '("#     * FFTW3 implementation of the FFT")'
#endif
#else
#ifdef SGI_FFT
    PRINT '("#     * SGI_FFT implementation of the FFT")'
#else
#ifdef IMKL_FFT
    PRINT '("#     * Intel MKL implementation of the FFT")'
#else
    PRINT '("#     * fourt implementation of the FFT")'
#endif
#endif
#endif
!$  PRINT '("#     * parallel OpenMP implementation with ",I3.3,"/",I3.3," threads")', &
!$                  omp_get_max_threads(),omp_get_num_procs()
#ifdef TXT
    IF (in%isoutputtxt) THEN
       PRINT '("#     * export to TXT format")'
    ELSE
       PRINT '("#     * export to TXT format cancelled                     (--",a,")")', TRIM(opts(3)%name)
    END IF
    IF (in%isoutputstress) THEN
       PRINT '("#     * export stress")'
    ELSE
       PRINT '("#     * stress export cancelled                            (--",a,")")', TRIM(opts(7)%name)
    END IF
#ifdef GRD
    IF (in%isoutputgrd) THEN
       PRINT '("#     * export to GRD format")'
    ELSE
       PRINT '("#     * export to GRD format cancelled                     (--",a,")")', TRIM(opts(5)%name)
    END IF
#endif
#ifdef XYZ
    IF (in%isoutputxyz) THEN
       PRINT '("#     * export to XYZ format")'
    ELSE
       PRINT '("#     * export to XYZ format cancelled                     (--",a,")")', TRIM(opts(6)%name)
    END IF
#endif
#endif
#ifdef VTK
    IF (in%isoutputvtk) THEN
       PRINT '("#     * export to VTK format")'
    ELSE
       PRINT '("#     * export to VTK format cancelled                     (--",a,")")', TRIM(opts(4)%name)
    END IF
    IF (in%isoutputvtkrelax) THEN
       PRINT '("#     * export relaxation component to VTK format   (--",a,")")', TRIM(opts(10)%name)
    END IF
#endif
    PRINT 2000

    IF (noptions .LT. COMMAND_ARGUMENT_COUNT()) THEN
       iunit=25
       CALL GET_COMMAND_ARGUMENT(noptions+1,filename)
       OPEN (UNIT=iunit,FILE=filename,IOSTAT=iostatus)
    ELSE
       ! default is standard input
       iunit=5
    END IF

    PRINT '("# grid dimension (sx1,sx2,sx3)")'
    CALL getdata(iunit,dataline)
    READ (dataline,*) in%sx1,in%sx2,in%sx3
    PRINT '(3I5)', in%sx1,in%sx2,in%sx3

    PRINT '("# sampling (dx1,dx2,dx3), smoothing (beta, nyquist)")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%dx1,in%dx2,in%dx3,in%beta,in%nyquist
    PRINT '(5ES9.2E1)', in%dx1,in%dx2,in%dx3,in%beta,in%nyquist

    PRINT '("# origin position (x0,y0) and rotation")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%x0,in%y0,in%rot
    PRINT '(3ES9.2E1)', in%x0,in%y0,in%rot

    PRINT '("# observation depth (displacement and stress)")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%oz,in%ozs
    PRINT '(2ES9.2E1)', in%oz,in%ozs

    PRINT '("# output directory")'
    CALL getdata(iunit,dataline)
    READ (dataline,'(a)') in%wdir

    in%reporttimefilename=TRIM(in%wdir)//"/time.txt"
    in%reportfilename=TRIM(in%wdir)//"/report.txt"
#ifdef TXT
    PRINT '(" ",a," (report: ",a,")")', TRIM(in%wdir),TRIM(in%reportfilename)
#else
    PRINT '(" ",a," (time report: ",a,")")', TRIM(in%wdir),TRIM(in%reporttimefilename)
#endif

    ! test write permissions on output directory
    OPEN (UNIT=14,FILE=in%reportfilename,POSITION="APPEND",&
            IOSTAT=iostatus,FORM="FORMATTED")
    IF (iostatus>0) THEN
       WRITE_DEBUG_INFO
       WRITE (0,'("unable to access ",a)') TRIM(in%reporttimefilename)
       STOP 1
    END IF
    CLOSE(14)
    ! end test

#ifdef VTK
    filename=TRIM(in%wdir)//"/cgrid.vtp"
    CALL exportvtk_grid(in%sx1,in%sx2,in%sx3,in%dx1,in%dx2,in%dx3,filename)
#endif

    PRINT '("# lambda, mu, gamma (gamma = (1 - nu) rho g / mu)")'
    CALL getdata(iunit,dataline)
    READ (dataline,*) in%lambda,in%mu,in%gam
    PRINT '(3ES10.2E2)',in%lambda,in%mu,in%gam

    PRINT '("# time interval, (positive time step) or (negative skip, scaling)")'
    CALL getdata(iunit,dataline)
    PRINT '(2x,a)', TRIM(dataline)
    READ  (dataline,*) in%interval, in%odt

    IF (in%odt .LT. 0.) THEN
       READ  (dataline,*) dum1, dum2, in%tscale
       in%skip=ceiling(-in%odt)
       PRINT '("# output every ",I3.3," steps, dt scaled by ",ES7.2E1)', in%skip,in%tscale
    ELSE
       PRINT '("# output every ",ES9.2E1," time unit")', in%odt
    END IF

    
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !           O B S E R V A T I O N          P L A N E S 
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of observation planes")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%nop
    PRINT '(I5)', in%nop
    IF (in%nop .gt. 0) THEN
       ALLOCATE(in%op(in%nop),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the observation plane list"
       PRINT 2000
       PRINT 2100
       PRINT 2000
       DO k=1,in%nop
          CALL getdata(iunit,dataline)
          READ  (dataline,*) i,in%op(k)%x,in%op(k)%y,in%op(k)%z,&
               in%op(k)%length,in%op(k)%width,in%op(k)%strike,in%op(k)%dip

          PRINT '(I3.3," ",5ES9.2E1,2f7.1)', &
               k,in%op(k)%x,in%op(k)%y,in%op(k)%z, &
               in%op(k)%length,in%op(k)%width,in%op(k)%strike,in%op(k)%dip

          IF (i .ne. k) THEN
             WRITE_DEBUG_INFO
             WRITE (0,*) "error in input file: plane index misfit", k,"<>",i
             STOP 1
          END IF

          ! comply to Wang's convention
          CALL wangconvention(dummy,in%op(k)%x,in%op(k)%y,in%op(k)%z,&
               in%op(k)%length,in%op(k)%width,in%op(k)%strike,in%op(k)%dip, &
               dummy,in%x0,in%y0,in%rot)

       END DO
    END IF


    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !         O B S E R V A T I O N       P O I N T S
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of observation points")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%npts
    PRINT '(I5)', in%npts
    IF (in%npts .gt. 0) THEN
       ALLOCATE(in%opts(in%npts),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the observation point list"
       ALLOCATE(in%ptsname(in%npts),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the list of point name"

       PRINT 2000
       PRINT 2300
       PRINT 2000
       DO k=1,in%npts
          CALL getdata(iunit,dataline)
          READ (dataline,*) i,in%ptsname(k),in%opts(k)%v1,in%opts(k)%v2,in%opts(k)%v3

          PRINT '(I3.3," ",A4,3ES9.2E1)', i,in%ptsname(k), &
               in%opts(k)%v1,in%opts(k)%v2,in%opts(k)%v3

          ! shift and rotate coordinates
          in%opts(k)%v1=in%opts(k)%v1-in%x0
          in%opts(k)%v2=in%opts(k)%v2-in%y0
          CALL rotation(in%opts(k)%v1,in%opts(k)%v2,in%rot)

          IF (i .ne. k) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: points index misfit")')
             STOP 1
          END IF
       END DO

       ! export the lits of observation points for display
       filename=TRIM(in%wdir)//"/opts.dat"
       CALL exportoptsdat(in%npts,in%opts,in%ptsname,filename)

    END IF

    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !   C O U L O M B      O B S E R V A T I O N      S E G M E N T S
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of stress observation segments")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%nsop
    PRINT '(I5)', in%nsop
    IF (in%nsop .gt. 0) THEN
       ALLOCATE(in%sop(in%nsop),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the segment list"
       PRINT 2000
       PRINT '("# n        xs       ys       zs  length   width strike   dip friction")'
       PRINT 2000
       DO k=1,in%nsop
          CALL getdata(iunit,dataline)
          READ (dataline,*) i, &
               in%sop(k)%x,in%sop(k)%y,in%sop(k)%z, &
               in%sop(k)%length,in%sop(k)%width, &
               in%sop(k)%strike,in%sop(k)%dip,in%sop(k)%friction
          in%sop(k)%sig0=TENSOR(0.d0,0.d0,0.d0,0.d0,0.d0,0.d0)

          PRINT '(I4.4,3ES9.2E1,2ES8.2E1,f7.1,f6.1,f7.1)',i, &
               in%sop(k)%x,in%sop(k)%y,in%sop(k)%z, &
               in%sop(k)%length,in%sop(k)%width, &
               in%sop(k)%strike,in%sop(k)%dip, &
               in%sop(k)%friction
             
          IF (i .ne. k) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("invalid segment definition ")')
             WRITE (0,'("error in input file: source index misfit")')
             STOP 1
          END IF
          IF (MAX(in%sop(k)%length,in%sop(k)%width) .LE. 0._8) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: length and width must be positive.")')
             STOP 1
          END IF

          ! comply to Wang's convention
          CALL wangconvention(dummy, &
                     in%sop(k)%x,in%sop(k)%y,in%sop(k)%z, &
                     in%sop(k)%length,in%sop(k)%width, &
                     in%sop(k)%strike,in%sop(k)%dip, &
                     dummy, &
                     in%x0,in%y0,in%rot)
       END DO

       ! export patches to vtk/vtp
       filename=TRIM(in%wdir)//"/rfaults-dsigma-0000.vtp"
       CALL exportvtk_rfaults_stress(in%sx1,in%sx2,in%sx3,in%dx1,in%dx2,in%dx3, &
                                     in%nsop,in%sop,filename,convention=1)

    END IF

    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !                     P R E S T R E S S
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of prestress interfaces")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%nps
    PRINT '(I5)', in%nps
    ALLOCATE(in%stressstruc(in%sx3/2),STAT=iostatus)
    IF (iostatus>0) STOP "could not allocate the background stress"

    IF (in%nps .GT. 0) THEN
       ALLOCATE(in%stresslayer(in%nps),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the stress layer structure"
       
       PRINT 2000
       PRINT '("# n    depth  sigma11  sigma12  sigma13  sigma22  sigma23  sigma33")'
       PRINT 2000
       DO k=1,in%nps
          CALL getdata(iunit,dataline)
          READ  (dataline,*) i,in%stresslayer(k)%z, &
               in%stresslayer(k)%t%s11, in%stresslayer(k)%t%s12, &
               in%stresslayer(k)%t%s13, in%stresslayer(k)%t%s22, &
               in%stresslayer(k)%t%s23, in%stresslayer(k)%t%s33
          
          PRINT '(I3.3,7ES9.2E1)', i, &
               in%stresslayer(k)%z, &
               in%stresslayer(k)%t%s11, in%stresslayer(k)%t%s12, &
               in%stresslayer(k)%t%s13, in%stresslayer(k)%t%s22, &
               in%stresslayer(k)%t%s23, in%stresslayer(k)%t%s33
          
          IF (i .ne. k) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: index misfit")')
             STOP 1
          END IF
       END DO
    END IF



    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    !  L I N E A R    V I S C O U S    I N T E R F A C E
    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of linear viscous interfaces")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%nv
    PRINT '(I5)', in%nv
    
    IF (in%nv .GT. 0) THEN
       ALLOCATE(in%linearlayer(in%nv),in%linearstruc(in%sx3/2),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the layer structure"
       
       PRINT 2000
       PRINT '("# n     depth    gamma0  cohesion")'
       PRINT 2000
       DO k=1,in%nv
          CALL getdata(iunit,dataline)
          READ  (dataline,*) i,in%linearlayer(k)%z, &
               in%linearlayer(k)%gammadot0, in%linearlayer(k)%cohesion

          in%linearlayer(k)%stressexponent=1

          PRINT '(I3.3,3ES10.2E2)', i, &
               in%linearlayer(k)%z, &
               in%linearlayer(k)%gammadot0, &
               in%linearlayer(k)%cohesion
          
          ! check positive strain rates
          IF (in%linearlayer(k)%gammadot0 .LT. 0) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: strain rates must be positive")')
             STOP 1
          END IF

          IF (i .ne. k) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: index misfit")')
             STOP 1
          END IF
#ifdef VTK
          ! export the viscous layer in VTK format
          WRITE (digit,'(I3.3)') k

          rffilename=TRIM(in%wdir)//"/linearlayer-"//digit//".vtp"
          CALL exportvtk_rectangle(0.d0,0.d0,in%linearlayer(k)%z, &
                                   DBLE(in%sx2)*in%dx2,DBLE(in%sx1)*in%dx1, &
                                   0._8,1.5708d0,rffilename)
#endif
       END DO

       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !                 L I N E A R   W E A K   Z O N E S
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       PRINT '("# number of linear weak zones")'
       CALL getdata(iunit,dataline)
       READ  (dataline,*) in%nlwz
       PRINT '(I5)', in%nlwz
       IF (in%nlwz .GT. 0) THEN
          ALLOCATE(in%linearweakzone(in%nlwz),in%linearweakzonec(in%nlwz),STAT=iostatus)
          IF (iostatus>0) STOP "could not allocate the linear weak zones"
          PRINT 2000
          PRINT '("#  n dgammadot0     x1       x2       x3  length   width thickn. strike   dip")'
          PRINT 2000
          DO k=1,in%nlwz
             CALL getdata(iunit,dataline)
             READ  (dataline,*) i, &
                  in%linearweakzone(k)%dgammadot0, &
                  in%linearweakzone(k)%x,in%linearweakzone(k)%y,in%linearweakzone(k)%z,&
                  in%linearweakzone(k)%length,in%linearweakzone(k)%width,in%linearweakzone(k)%thickness, &
                  in%linearweakzone(k)%strike,in%linearweakzone(k)%dip
          
             in%linearweakzonec(k)=in%linearweakzone(k)
             
             PRINT '(I4.4,4ES9.2E1,3ES8.2E1,f7.1,f6.1)',k,&
                  in%linearweakzone(k)%dgammadot0, &
                  in%linearweakzone(k)%x,in%linearweakzone(k)%y,in%linearweakzone(k)%z, &
                  in%linearweakzone(k)%length,in%linearweakzone(k)%width, &
                  in%linearweakzone(k)%thickness, &
                  in%linearweakzone(k)%strike,in%linearweakzone(k)%dip
             
             IF (i .ne. k) THEN
                WRITE_DEBUG_INFO
                WRITE (0,'("error in input file: source index misfit")')
                STOP 1
             END IF
             ! comply to Wang's convention
             CALL wangconvention( &
                  dummy, & 
                  in%linearweakzone(k)%x,in%linearweakzone(k)%y,in%linearweakzone(k)%z, &
                  in%linearweakzone(k)%length,in%linearweakzone(k)%width, &
                  in%linearweakzone(k)%strike,in%linearweakzone(k)%dip, &
                  dummy,in%x0,in%y0,in%rot)

             WRITE (digit,'(I3.3)') k

#ifdef VTK
             ! export the ductile zone in VTK format
             !rffilename=TRIM(in%wdir)//"/weakzone-"//digit//".vtp"
             !CALL exportvtk_brick(in%linearweakzone(k)%x,in%linearweakzone(k)%y,in%linearweakzone(k)%z, &
             !                     in%linearweakzone(k)%length,in%linearweakzone(k)%width,in%linearweakzone(k)%thickness, &
             !                     in%linearweakzone(k)%strike,in%linearweakzone(k)%dip,rffilename)
#endif
             ! export the ductile zone in GMT .xy format
             rffilename=TRIM(in%wdir)//"/weakzone-"//digit//".xy"
             CALL exportxy_brick(in%linearweakzone(k)%x,in%linearweakzone(k)%y,in%linearweakzone(k)%z, &
                                 in%linearweakzone(k)%length,in%linearweakzone(k)%width,in%linearweakzone(k)%thickness, &
                                 in%linearweakzone(k)%strike,in%linearweakzone(k)%dip,rffilename)
          END DO
#ifdef VTK
          ! export the ductile zone in VTK format
          rffilename=TRIM(in%wdir)//"/weakzones-linear.vtp"
          CALL exportvtk_allbricks(in%nlwz,in%linearweakzone,rffilename)
#endif
       END IF
    END IF ! end linear viscous
       
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !  N O N L I N E A R    V I S C O U S    I N T E R F A C E
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of nonlinear viscous interfaces")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%npl
    PRINT '(I5)', in%npl

    IF (in%npl .GT. 0) THEN
       ALLOCATE(in%nonlinearlayer(in%npl),in%nonlinearstruc(in%sx3/2),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the layer structure"
       
       PRINT 2000
       PRINT '("# n     depth    gamma0     power  cohesion")'
       PRINT 2000
       DO k=1,in%npl
          CALL getdata(iunit,dataline)

          READ  (dataline,*) i,in%nonlinearlayer(k)%z, &
               in%nonlinearlayer(k)%gammadot0, &
               in%nonlinearlayer(k)%stressexponent, &
               in%nonlinearlayer(k)%cohesion

          PRINT '(I3.3,4ES10.2E2)', i, &
               in%nonlinearlayer(k)%z, &
               in%nonlinearlayer(k)%gammadot0, &
               in%nonlinearlayer(k)%stressexponent, &
               in%nonlinearlayer(k)%cohesion
          
          ! check positive strain rates
          IF (in%nonlinearlayer(k)%gammadot0 .LT. 0) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: strain rates must be positive")')
             STOP 1
          END IF

          IF (i .ne. k) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: index misfit")')
             STOP 1
          END IF

#ifdef VTK
          WRITE (digit,'(I3.3)') k

          ! export the viscous layer in VTK format
          rffilename=TRIM(in%wdir)//"/nonlinearlayer-"//digit//".vtp"
          CALL exportvtk_rectangle(0.d0,0.d0,in%nonlinearlayer(k)%z, &
                                   DBLE(in%sx2)*in%dx2,DBLE(in%sx1)*in%dx1, &
                                   0._8,1.57d0,rffilename)
#endif
       END DO

       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !           N O N L I N E A R   W E A K   Z O N E S
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       PRINT '("# number of nonlinear weak zones")'
       CALL getdata(iunit,dataline)
       READ  (dataline,*) in%nnlwz
       PRINT '(I5)', in%nnlwz
       IF (in%nnlwz .GT. 0) THEN
          ALLOCATE(in%nonlinearweakzone(in%nnlwz),in%nonlinearweakzonec(in%nnlwz),STAT=iostatus)
          IF (iostatus>0) STOP "could not allocate the nonlinear weak zones"
          PRINT 2000
          PRINT '("#   n dgammadot0     x1       x2       x3  length   width thickn. strike   dip")'
          PRINT 2000
          DO k=1,in%nnlwz
             CALL getdata(iunit,dataline)
             READ  (dataline,*) i, &
                  in%nonlinearweakzone(k)%dgammadot0, &
                  in%nonlinearweakzone(k)%x,in%nonlinearweakzone(k)%y,in%nonlinearweakzone(k)%z,&
                  in%nonlinearweakzone(k)%length,in%nonlinearweakzone(k)%width,in%nonlinearweakzone(k)%thickness, &
                  in%nonlinearweakzone(k)%strike,in%nonlinearweakzone(k)%dip
          
             in%nonlinearweakzonec(k)=in%nonlinearweakzone(k)
             
             PRINT '(I5.5,4ES9.2E1,3ES8.2E1,f7.1,f6.1)',k,&
                  in%nonlinearweakzone(k)%dgammadot0, &
                  in%nonlinearweakzone(k)%x,in%nonlinearweakzone(k)%y,in%nonlinearweakzone(k)%z, &
                  in%nonlinearweakzone(k)%length,in%nonlinearweakzone(k)%width, &
                  in%nonlinearweakzone(k)%thickness, &
                  in%nonlinearweakzone(k)%strike,in%nonlinearweakzone(k)%dip
             
             IF (i .ne. k) THEN
                WRITE_DEBUG_INFO
                WRITE (0,'("error in input file: source index misfit")')
                STOP 1
             END IF
             ! comply to Wang's convention
             CALL wangconvention( &
                  dummy, & 
                  in%nonlinearweakzone(k)%x,in%nonlinearweakzone(k)%y,in%nonlinearweakzone(k)%z, &
                  in%nonlinearweakzone(k)%length,in%nonlinearweakzone(k)%width, &
                  in%nonlinearweakzone(k)%strike,in%nonlinearweakzone(k)%dip, &
                  dummy,in%x0,in%y0,in%rot)

                  WRITE (digit,'(I3.3)') k

#ifdef VTK
                  ! export the ductile zone in VTK format
                  !rffilename=TRIM(in%wdir)//"/weakzone-nl-"//digit//".vtp"
                  !CALL exportvtk_brick(in%nonlinearweakzone(k)%x, &
                  !                     in%nonlinearweakzone(k)%y, &
                  !                     in%nonlinearweakzone(k)%z, &
                  !                     in%nonlinearweakzone(k)%length, &
                  !                     in%nonlinearweakzone(k)%width, &
                  !                     in%nonlinearweakzone(k)%thickness, &
                  !                     in%nonlinearweakzone(k)%strike, &
                  !                     in%nonlinearweakzone(k)%dip,rffilename)
#endif
                  ! export the ductile zone in GMT .xy format
                  rffilename=TRIM(in%wdir)//"/weakzone-nl-"//digit//".xy"
                  CALL exportxy_brick(in%nonlinearweakzone(k)%x, &
                                       in%nonlinearweakzone(k)%y, &
                                       in%nonlinearweakzone(k)%z, &
                                       in%nonlinearweakzone(k)%length, &
                                       in%nonlinearweakzone(k)%width, &
                                       in%nonlinearweakzone(k)%thickness, &
                                       in%nonlinearweakzone(k)%strike, &
                                       in%nonlinearweakzone(k)%dip,rffilename)
          END DO
#ifdef VTK
          ! export the ductile zone in VTK format
          rffilename=TRIM(in%wdir)//"/weakzones-nonlinear.vtp"
          CALL exportvtk_allbricks(in%nnlwz,in%nonlinearweakzone,rffilename)
#endif
       END IF
    END IF ! end nonlinear viscous


    IF (in%istransient) THEN
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  T R A N S I E N T   I N T E R F A C E
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       PRINT '("# number of linear transient interfaces")'
       CALL getdata(iunit,dataline)
       READ  (dataline,*) in%nlt
       PRINT '(I5)', in%nlt

       IF (in%nlt .GT. 0) THEN
          ALLOCATE(in%ltransientlayer(in%nlt),in%ltransientstruc(in%sx3/2),STAT=iostatus)
          IF (iostatus>0) STOP "could not allocate the layer structure"
          
          PRINT 2000
          PRINT '("# n     depth    gamma0        Gk")'
          PRINT 2000
          DO k=1,in%nlt
             CALL getdata(iunit,dataline)

             READ  (dataline,*) i,in%ltransientlayer(k)%z, &
                     in%ltransientlayer(k)%gammadot0, &
                     in%ltransientlayer(k)%Gk
             in%ltransientlayer(k)%stressexponent=1

             PRINT '(I3.3,4ES10.2E2)', i, &
                  in%ltransientlayer(k)%z, &
                  in%ltransientlayer(k)%gammadot0, &
                  in%ltransientlayer(k)%Gk
             
             ! check positive strain rates
             IF (in%ltransientlayer(k)%gammadot0 .LT. 0) THEN
                WRITE_DEBUG_INFO
                WRITE (0,'("error in input file: strain rates must be positive")')
                STOP 1
             END IF

             IF (i .ne. k) THEN
                WRITE_DEBUG_INFO
                WRITE (0,'("error in input file: index misfit")')
                STOP 1
             END IF

#ifdef VTK
             WRITE (digit,'(I3.3)') k

             ! export the viscous layer in VTK format
             rffilename=TRIM(in%wdir)//"/ltransientlayer-"//digit//".vtp"
             CALL exportvtk_rectangle(0.d0,0.d0,in%ltransientlayer(k)%z, &
                                      DBLE(in%sx2)*in%dx2,DBLE(in%sx1)*in%dx1, &
                                      0._8,1.57d0,rffilename)
#endif
          END DO

          ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          !          L I N E A R   T R A N S I E N T   W E A K   Z O N E S
          ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          PRINT '("# number of transient weak zones")'
          CALL getdata(iunit,dataline)
          READ  (dataline,*) in%nltwz
          PRINT '(I5)', in%nltwz
          IF (in%nltwz .GT. 0) THEN
             ALLOCATE(in%ltransientweakzone(in%nltwz),in%ltransientweakzonec(in%nltwz),STAT=iostatus)
             IF (iostatus>0) STOP "could not allocate the nonlinear weak zones"
             PRINT 2000
             PRINT '("#  n dgammadot0     x1       x2       x3  length   width thickn. strike   dip")'
             PRINT 2000
             DO k=1,in%nltwz
                CALL getdata(iunit,dataline)
                READ  (dataline,*) i, &
                     in%ltransientweakzone(k)%dgammadot0, &
                     in%ltransientweakzone(k)%x,in%ltransientweakzone(k)%y,in%ltransientweakzone(k)%z,&
                     in%ltransientweakzone(k)%length,in%ltransientweakzone(k)%width,in%ltransientweakzone(k)%thickness, &
                     in%ltransientweakzone(k)%strike,in%ltransientweakzone(k)%dip
             
                in%ltransientweakzonec(k)=in%ltransientweakzone(k)
                
                PRINT '(I4.4,4ES9.2E1,3ES8.2E1,f7.1,f6.1)',k,&
                     in%ltransientweakzone(k)%dgammadot0, &
                     in%ltransientweakzone(k)%x,in%ltransientweakzone(k)%y,in%ltransientweakzone(k)%z, &
                     in%ltransientweakzone(k)%length,in%ltransientweakzone(k)%width, &
                     in%ltransientweakzone(k)%thickness, &
                     in%ltransientweakzone(k)%strike,in%ltransientweakzone(k)%dip
                
                IF (i .ne. k) THEN
                   WRITE_DEBUG_INFO
                   WRITE (0,'("error in input file: source index misfit")')
                   STOP 1
                END IF
                ! comply to Wang's convention
                CALL wangconvention( &
                     dummy, & 
                     in%ltransientweakzone(k)%x,in%ltransientweakzone(k)%y,in%ltransientweakzone(k)%z, &
                     in%ltransientweakzone(k)%length,in%ltransientweakzone(k)%width, &
                     in%ltransientweakzone(k)%strike,in%ltransientweakzone(k)%dip, &
                     dummy,in%x0,in%y0,in%rot)

                     WRITE (digit,'(I3.3)') k

#ifdef VTK
                     ! export the ductile zone in VTK format
                     !rffilename=TRIM(in%wdir)//"/weakzone-nl-"//digit//".vtp"
                     !CALL exportvtk_brick(in%ltransientweakzone(k)%x, &
                     !                     in%ltransientweakzone(k)%y, &
                     !                     in%ltransientweakzone(k)%z, &
                     !                     in%ltransientweakzone(k)%length, &
                     !                     in%ltransientweakzone(k)%width, &
                     !                     in%ltransientweakzone(k)%thickness, &
                     !                     in%ltransientweakzone(k)%strike, &
                     !                     in%ltransientweakzone(k)%dip,rffilename)
#endif
                     ! export the ductile zone in GMT .xy format
                     rffilename=TRIM(in%wdir)//"/weakzone-nl-"//digit//".xy"
                     CALL exportxy_brick(in%ltransientweakzone(k)%x, &
                                          in%ltransientweakzone(k)%y, &
                                          in%ltransientweakzone(k)%z, &
                                          in%ltransientweakzone(k)%length, &
                                          in%ltransientweakzone(k)%width, &
                                          in%ltransientweakzone(k)%thickness, &
                                          in%ltransientweakzone(k)%strike, &
                                          in%ltransientweakzone(k)%dip,rffilename)
             END DO
#ifdef VTK
             ! export the ductile zone in VTK format
             rffilename=TRIM(in%wdir)//"/weakzones-nonlinear.vtp"
             CALL exportvtk_allbricks(in%nnlwz,in%ltransientweakzone,rffilename)
#endif
          END IF
       END IF ! end linear transient  

       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  N O N - L I N E A R   T R A N S I E N T   I N T E R F A C E
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       PRINT '("# number of nonlinear transient interfaces")'
       CALL getdata(iunit,dataline)
       READ  (dataline,*) in%nnlt
       PRINT '(I5)', in%nnlt

       IF (in%nnlt .GT. 0) THEN
          ALLOCATE(in%nltransientlayer(in%nnlt),in%nltransientstruc(in%sx3/2),STAT=iostatus)
          IF (iostatus>0) STOP "could not allocate the layer structure"
          
          PRINT 2000
          PRINT '("# n     depth    gamma0     power        Gk")'
          PRINT 2000
          DO k=1,in%nnlt
             CALL getdata(iunit,dataline)

                READ  (dataline,*) i,in%nltransientlayer(k)%z, &
                     in%nltransientlayer(k)%gammadot0, &
                     in%nltransientlayer(k)%stressexponent, &
                     in%nltransientlayer(k)%Gk

             PRINT '(I3.3,4ES10.2E2)', i, &
                  in%nltransientlayer(k)%z, &
                  in%nltransientlayer(k)%gammadot0, &
                  in%nltransientlayer(k)%stressexponent, &
                  in%nltransientlayer(k)%Gk
             
             ! check positive strain rates
             IF (in%nltransientlayer(k)%gammadot0 .LT. 0) THEN
                WRITE_DEBUG_INFO
                WRITE (0,'("error in input file: strain rates must be positive")')
                STOP 1
             END IF

             IF (i .ne. k) THEN
                WRITE_DEBUG_INFO
                WRITE (0,'("error in input file: index misfit")')
                STOP 1
             END IF

#ifdef VTK
             WRITE (digit,'(I3.3)') k

             ! export the viscous layer in VTK format
             rffilename=TRIM(in%wdir)//"/nltransientlayer-"//digit//".vtp"
             CALL exportvtk_rectangle(0.d0,0.d0,in%nltransientlayer(k)%z, &
                                      DBLE(in%sx2)*in%dx2,DBLE(in%sx1)*in%dx1, &
                                      0._8,1.57d0,rffilename)
#endif
          END DO

          ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          !         N O N L I N E A R   T R A N S I E N T   W E A K   Z O N E S
          ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          PRINT '("# number of transient weak zones")'
          CALL getdata(iunit,dataline)
          READ  (dataline,*) in%nnltwz
          PRINT '(I5)', in%nnltwz

          IF (in%nnltwz .GT. 0) THEN
             ALLOCATE(in%nltransientweakzone(in%nnltwz),in%nltransientweakzonec(in%nnltwz),STAT=iostatus)
             IF (iostatus>0) STOP "could not allocate the nonlinear weak zones"
             PRINT 2000
             PRINT '("#  n dgammadot0     x1       x2       x3  length   width thickn. strike   dip")'
             PRINT 2000
             DO k=1,in%nnltwz
                CALL getdata(iunit,dataline)
                READ  (dataline,*) i, &
                     in%nltransientweakzone(k)%dgammadot0, &
                     in%nltransientweakzone(k)%x,in%nltransientweakzone(k)%y,in%nltransientweakzone(k)%z,&
                     in%nltransientweakzone(k)%length,in%nltransientweakzone(k)%width,in%nltransientweakzone(k)%thickness, &
                     in%nltransientweakzone(k)%strike,in%nltransientweakzone(k)%dip
             
                in%nltransientweakzonec(k)=in%nltransientweakzone(k)
                
                PRINT '(I4.4,4ES9.2E1,3ES8.2E1,f7.1,f6.1)',k,&
                     in%nltransientweakzone(k)%dgammadot0, &
                     in%nltransientweakzone(k)%x,in%nltransientweakzone(k)%y,in%nltransientweakzone(k)%z, &
                     in%nltransientweakzone(k)%length,in%nltransientweakzone(k)%width, &
                     in%nltransientweakzone(k)%thickness, &
                     in%nltransientweakzone(k)%strike,in%nltransientweakzone(k)%dip
                
                IF (i .ne. k) THEN
                   WRITE_DEBUG_INFO
                   WRITE (0,'("error in input file: source index misfit")')
                   STOP 1
                END IF
                ! comply to Wang's convention
                CALL wangconvention( &
                     dummy, & 
                     in%nltransientweakzone(k)%x,in%nltransientweakzone(k)%y,in%nltransientweakzone(k)%z, &
                     in%nltransientweakzone(k)%length,in%nltransientweakzone(k)%width, &
                     in%nltransientweakzone(k)%strike,in%nltransientweakzone(k)%dip, &
                     dummy,in%x0,in%y0,in%rot)

                     WRITE (digit,'(I3.3)') k

#ifdef VTK
                     ! export the ductile zone in VTK format
                     !rffilename=TRIM(in%wdir)//"/weakzone-nl-"//digit//".vtp"
                     !CALL exportvtk_brick(in%nltransientweakzone(k)%x, &
                     !                     in%nltransientweakzone(k)%y, &
                     !                     in%nltransientweakzone(k)%z, &
                     !                     in%nltransientweakzone(k)%length, &
                     !                     in%nltransientweakzone(k)%width, &
                     !                     in%nltransientweakzone(k)%thickness, &
                     !                     in%nltransientweakzone(k)%strike, &
                     !                     in%nltransientweakzone(k)%dip,rffilename)
#endif
                     ! export the ductile zone in GMT .xy format
                     rffilename=TRIM(in%wdir)//"/weakzone-nltr-"//digit//".xy"
                     CALL exportxy_brick(in%nltransientweakzone(k)%x, &
                                          in%nltransientweakzone(k)%y, &
                                          in%nltransientweakzone(k)%z, &
                                          in%nltransientweakzone(k)%length, &
                                          in%nltransientweakzone(k)%width, &
                                          in%nltransientweakzone(k)%thickness, &
                                          in%nltransientweakzone(k)%strike, &
                                          in%nltransientweakzone(k)%dip,rffilename)
             END DO
#ifdef VTK
             ! export the ductile zone in VTK format
             rffilename=TRIM(in%wdir)//"/weakzones-nonlinear-transient.vtp"
             CALL exportvtk_allbricks(in%nnlwz,in%nltransientweakzone,rffilename)
#endif
          END IF
       END IF ! end nonlinear transient  
    END IF ! end istransient

    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !                 F A U L T    C R E E P
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of fault creep interfaces")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%nfc
    PRINT '(I5)', in%nfc

    in%np=0
    IF (in%nfc .GT. 0) THEN
       ALLOCATE(in%faultcreeplayer(in%nfc),in%faultcreepstruc(in%sx3/2),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the layer structure"

       PRINT 2000
       PRINT '("# n    depth   gamma0 (a-b)sig friction cohesion")'
       PRINT 2000
       DO k=1,in%nfc
          CALL getdata(iunit,dataline)
          READ  (dataline,*) i,in%faultcreeplayer(k)%z, &
               in%faultcreeplayer(k)%gammadot0, &
               in%faultcreeplayer(k)%stressexponent, &
               in%faultcreeplayer(k)%friction, &
               in%faultcreeplayer(k)%cohesion

          PRINT '(I3.3,5ES9.2E1)', i, &
               in%faultcreeplayer(k)%z, &
               in%faultcreeplayer(k)%gammadot0, &
               in%faultcreeplayer(k)%stressexponent, &
               in%faultcreeplayer(k)%friction, &
               in%faultcreeplayer(k)%cohesion

          ! check positive strain rates
          IF (in%faultcreeplayer(k)%gammadot0 .LT. 0) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: slip rates must be positive")')
             STOP 1
          END IF

          IF (i .ne. k) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: index misfit")')
             STOP 1
          END IF

       END DO

       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !             A F T E R S L I P       P L A N E S
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       PRINT '("# number of afterslip planes")'
       CALL getdata(iunit,dataline)
       READ  (dataline,*) in%np
       PRINT '(I5)', in%np
       
       IF (in%np .gt. 0) THEN
          ALLOCATE(in%n(in%np),STAT=iostatus)
          IF (iostatus>0) STOP "could not allocate the plane list"
       
          PRINT 2000
          PRINT 2500
          PRINT 2000
          
          DO k=1,in%np
             CALL getdata(iunit,dataline)
             READ (dataline,*) i, &
                  in%n(k)%x,in%n(k)%y,in%n(k)%z,&
                  in%n(k)%length,in%n(k)%width, &
                  in%n(k)%strike,in%n(k)%dip,in%n(k)%rake
             
             PRINT '(I3.3," ",5ES9.2E1,3f7.1)',i, &
                  in%n(k)%x,in%n(k)%y,in%n(k)%z, &
                  in%n(k)%length,in%n(k)%width, &
                  in%n(k)%strike,in%n(k)%dip,in%n(k)%rake

             IF (i .ne. k) THEN
                WRITE_DEBUG_INFO
                WRITE (0,'("error in input file: plane index misfit")')
                STOP 1
             END IF

             ! modify rake for consistency with slip model
             IF (in%n(k)%rake .GE. 0.d0) THEN
                in%n(k)%rake=in%n(k)%rake-180.d0
             ELSE             
                in%n(k)%rake=in%n(k)%rake+180.d0
             END IF

             ! comply to Wang's convention
             CALL wangconvention(dummy,in%n(k)%x,in%n(k)%y,in%n(k)%z,&
                  in%n(k)%length,in%n(k)%width, &
                  in%n(k)%strike,in%n(k)%dip,in%n(k)%rake, &
                  in%x0,in%y0,in%rot)

             ! number of patches in each direction
             in%n(k)%px2=FIX(in%n(k)%length/in%dx2)
             in%n(k)%px3=FIX(in%n(k)%width/in%dx3)

             ALLOCATE(in%n(k)%patch(in%n(k)%px2,in%n(k)%px3),STAT=iostatus)
             IF (iostatus>0) STOP "could not allocate the fault patches"
             in%n(k)%patch(:,:)=SLIPPATCH_STRUCT(0,0,0,0,0,0,0,0,0,0,0,0,TENSOR(0,0,0,0,0,0))

#ifdef VTK
             ! export the afterslip segment in VTK format
             WRITE (digit4,'(I4.4)') k

             rffilename=TRIM(in%wdir)//"/aplane-"//digit4//".vtp"
             CALL exportvtk_rectangle(in%n(k)%x,in%n(k)%y,in%n(k)%z, &
                                      in%n(k)%length,in%n(k)%width, &
                                      in%n(k)%strike,in%n(k)%dip,rffilename)
#endif

          END DO
       END IF
       
    END IF

    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    !     I N T E R - S E I S M I C    L O A D I N G
    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    minlength=in%sx1*in%dx1+in%sx2*in%dx2
    minwidth=in%sx3*in%dx3
    
    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    !        S H E A R     S O U R C E S   R A T E
    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of inter-seismic strike-slip segments")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%inter%ns
    PRINT '(I5)', in%inter%ns
    IF (in%inter%ns .GT. 0) THEN
       ALLOCATE(in%inter%s(in%inter%ns),in%inter%sc(in%inter%ns),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the source list"
       PRINT 2000
       PRINT '("#  n  slip/time  xs ys zs  length width  strike dip rake")'
       PRINT 2000
       DO k=1,in%inter%ns
          CALL getdata(iunit,dataline)
          READ (dataline,*) i,in%inter%s(k)%slip, &
               in%inter%s(k)%x,in%inter%s(k)%y,in%inter%s(k)%z, &
               in%inter%s(k)%length,in%inter%s(k)%width, &
               in%inter%s(k)%strike,in%inter%s(k)%dip,in%inter%s(k)%rake
          in%inter%s(k)%opening=0

          ! copy the input format for display
          in%inter%sc(k)=in%inter%s(k)
             
          PRINT '(I4.4,4ES9.2E1,2ES8.2E1,f7.1,f6.1,f7.1)',i, &
               in%inter%sc(k)%slip,&
               in%inter%sc(k)%x,in%inter%sc(k)%y,in%inter%sc(k)%z, &
               in%inter%sc(k)%length,in%inter%sc(k)%width, &
               in%inter%sc(k)%strike,in%inter%sc(k)%dip, &
               in%inter%sc(k)%rake
          
          IF (i .ne. k) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: source index misfit")')
             STOP 1
          END IF
          IF (MAX(in%inter%s(k)%length,in%inter%s(k)%width) .LE. 0._8) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: lengths must be positive.")')
             STOP 1
          END IF
          IF (in%inter%s(k)%length .lt. minlength) THEN
             minlength=in%inter%s(k)%length
          END IF
          IF (in%inter%s(k)%width  .lt. minwidth ) THEN
             minwidth =in%inter%s(k)%width
          END IF
          
          ! smooth out the slip distribution
          CALL antialiasingfilter(in%inter%s(k)%slip, &
                      in%inter%s(k)%length,in%inter%s(k)%width, &
                      in%dx1,in%dx2,in%dx3,in%nyquist)

          ! comply to Wang's convention
          CALL wangconvention(in%inter%s(k)%slip, &
               in%inter%s(k)%x,in%inter%s(k)%y,in%inter%s(k)%z, &
               in%inter%s(k)%length,in%inter%s(k)%width, &
               in%inter%s(k)%strike,in%inter%s(k)%dip, &
               in%inter%s(k)%rake, &
               in%x0,in%y0,in%rot)

       END DO
       PRINT 2000
    END IF
    
    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    !       T E N S I L E   S O U R C E S   R A T E
    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of inter-seismic tensile segments")'
    CALL getdata(iunit,dataline)
    READ  (dataline,*) in%inter%nt
    PRINT '(I5)', in%inter%nt
    IF (in%inter%nt .GT. 0) THEN
       ALLOCATE(in%inter%ts(in%inter%nt),in%inter%tsc(in%inter%nt),STAT=iostatus)
       IF (iostatus>0) STOP "could not allocate the tensile source list"
       PRINT 2000
       PRINT '("#  n  opening       xs       ys       ","zs  length   width strike   dip")'
       PRINT 2000
       DO k=1,in%inter%nt
          CALL getdata(iunit,dataline)
          READ  (dataline,*) i,in%inter%ts(k)%opening, &
               in%inter%ts(k)%x,in%inter%ts(k)%y,in%inter%ts(k)%z, &
               in%inter%ts(k)%length,in%inter%ts(k)%width, &
               in%inter%ts(k)%strike,in%inter%ts(k)%dip

          in%inter%ts(k)%slip=0._8
          ! copy the input format for display
          in%inter%tsc(k)=in%inter%ts(k)
          
          PRINT '(I4.4,4ES9.2E1,2ES8.2E1,f7.1,f6.1)', i, &
               in%inter%tsc(k)%opening, &
               in%inter%tsc(k)%x,in%inter%tsc(k)%y,in%inter%tsc(k)%z, &
               in%inter%tsc(k)%length,in%inter%tsc(k)%width, &
               in%inter%tsc(k)%strike,in%inter%tsc(k)%dip
          
          IF (i .ne. k) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: tensile source index misfit")')
             STOP 1
          END IF
          IF (MAX(in%inter%ts(k)%length,in%inter%ts(k)%width) .LE. 0._8) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'("error in input file: lengths must be positive.")')
             STOP 1
          END IF
          IF (in%inter%ts(k)%length .lt. minlength) THEN
             minlength=in%inter%ts(k)%length
          END IF
          IF (in%inter%ts(k)%width  .lt. minwidth) THEN
             minwidth =in%inter%ts(k)%width
          END IF
          
          ! smooth out the slip distribution
          CALL antialiasingfilter(in%inter%ts(k)%slip, &
                           in%inter%ts(k)%length,in%inter%ts(k)%width, &
                           in%dx1,in%dx2,in%dx3,in%nyquist)

          ! comply to Wang's convention
          CALL wangconvention(in%inter%ts(k)%slip, &
               in%inter%ts(k)%x,in%inter%ts(k)%y,in%inter%ts(k)%z, &
               in%inter%ts(k)%length,in%inter%ts(k)%width, &
               in%inter%ts(k)%strike,in%inter%ts(k)%dip,dummy, &
               in%x0,in%y0,in%rot)

       END DO
       PRINT 2000
    END IF
       
    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    !       C 0 - S E I S M I C     E V E N T S
    ! - - - - - - - - - - - - - - - - - - - - - - - - - -
    PRINT '("# number of events")'
    CALL getdata(iunit,dataline)
    READ (dataline,*) in%ne
    PRINT '(I5)', in%ne
    IF (in%ne .GT. 0) ALLOCATE(in%events(in%ne),STAT=iostatus)
    IF (iostatus>0) STOP "could not allocate the event list"
    
    DO e=1,in%ne
       IF (1 .NE. e) THEN
          PRINT '("# time of next event")'
          CALL getdata(iunit,dataline)
          READ (dataline,*) in%events(e)%time
          
          IF (0 .EQ. in%skip) THEN
             ! change event time to multiples of output time step
             in%events(e)%time=nint(in%events(e)%time/in%odt)*in%odt
          END IF

          PRINT '(ES9.2E1," (multiple of ",ES9.2E1,")")', &
               in%events(e)%time,in%odt

          IF (in%events(e)%time .LE. in%events(e-1)%time) THEN
             WRITE_DEBUG_INFO
             WRITE (0,'(a,a)') "input file error. ", &
                  "coseismic source time must increase. interrupting."
             STOP 1
          END IF
       ELSE
          in%events(1)%time=0._8
          in%events(1)%i=0
       END IF

       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       !           S H E A R     S O U R C E S
       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       PRINT '("# number of coseismic strike-slip segments")'
       CALL getdata(iunit,dataline)
       READ  (dataline,*) in%events(e)%ns
       PRINT '(I5)', in%events(e)%ns
       IF (in%events(e)%ns .GT. 0) THEN
          ALLOCATE(in%events(e)%s(in%events(e)%ns),in%events(e)%sc(in%events(e)%ns), &
               STAT=iostatus)
          IF (iostatus>0) STOP "could not allocate the source list"
          PRINT 2000
          PRINT '("#  n     slip       xs       ys       zs  length   width strike   dip   rake")'
          PRINT 2000
          DO k=1,in%events(e)%ns
             CALL getdata(iunit,dataline)
             READ (dataline,*,IOSTAT=iostatus) i,in%events(e)%s(k)%slip, &
                  in%events(e)%s(k)%x,in%events(e)%s(k)%y,in%events(e)%s(k)%z, &
                  in%events(e)%s(k)%length,in%events(e)%s(k)%width, &
                  in%events(e)%s(k)%strike,in%events(e)%s(k)%dip,in%events(e)%s(k)%rake, &
                  in%events(e)%s(k)%beta
             in%events(e)%s(k)%opening=0

             SELECT CASE(iostatus)
             CASE (1:)
                WRITE_DEBUG_INFO
                WRITE (0,'("invalid shear source definition at line")')
                WRITE (0,'(a)') dataline
                STOP 1
             CASE (0)
                IF (in%events(e)%s(k)%beta.GT.0.5d8) STOP "invalid smoothing parameter (beta)."
             CASE (:-1)
                ! use default value for smoothing
                in%events(e)%s(k)%beta=in%beta
             END SELECT

             ! copy the input format for display
             in%events(e)%sc(k)=in%events(e)%s(k)
             
             IF (iostatus.NE.0) THEN
                PRINT '(I4.4,4ES9.2E1,2ES8.2E1,f7.1,f6.1,f7.1)',i, &
                     in%events(e)%sc(k)%slip,&
                     in%events(e)%sc(k)%x,in%events(e)%sc(k)%y,in%events(e)%sc(k)%z, &
                     in%events(e)%sc(k)%length,in%events(e)%sc(k)%width, &
                     in%events(e)%sc(k)%strike,in%events(e)%sc(k)%dip, &
                     in%events(e)%sc(k)%rake
             ELSE
                ! print the smoothing value for this patch
                PRINT '(I4.4,4ES9.2E1,2ES8.2E1,f7.1,f6.1,f7.1,f6.1)',i, &
                     in%events(e)%sc(k)%slip,&
                     in%events(e)%sc(k)%x,in%events(e)%sc(k)%y,in%events(e)%sc(k)%z, &
                     in%events(e)%sc(k)%length,in%events(e)%sc(k)%width, &
                     in%events(e)%sc(k)%strike,in%events(e)%sc(k)%dip, &
                     in%events(e)%sc(k)%rake,in%events(e)%sc(k)%beta
             END IF
             
             IF (i .ne. k) THEN
                WRITE_DEBUG_INFO
                WRITE (0,'("invalid shear source definition ")')
                WRITE (0,'("error in input file: source index misfit")')
                STOP 1
             END IF
             IF (MAX(in%events(e)%s(k)%length,in%events(e)%s(k)%width) .LE. 0._8) THEN
                WRITE_DEBUG_INFO
                WRITE (0,'("error in input file: lengths must be positive.")')
                STOP 1
             END IF
             IF (in%events(e)%s(k)%length .lt. minlength) THEN
                minlength=in%events(e)%s(k)%length
             END IF
             IF (in%events(e)%s(k)%width  .lt. minwidth ) THEN
                minwidth =in%events(e)%s(k)%width
             END IF
             
             ! this is replaced by the exact solution (Okada 1992)
             ! smooth out the slip distribution
             !CALL antialiasingfilter(in%events(e)%s(k)%slip, &
             !                 in%events(e)%s(k)%length,in%events(e)%s(k)%width, &
             !                 in%dx1,in%dx2,in%dx3,in%nyquist)

             ! comply to Wang's convention
             CALL wangconvention(in%events(e)%s(k)%slip, &
                  in%events(e)%s(k)%x,in%events(e)%s(k)%y,in%events(e)%s(k)%z, &
                  in%events(e)%s(k)%length,in%events(e)%s(k)%width, &
                  in%events(e)%s(k)%strike,in%events(e)%s(k)%dip, &
                  in%events(e)%s(k)%rake, &
                  in%x0,in%y0,in%rot)

          END DO

#ifdef VTK
          ! export the fault segments in VTK format for the current event
          WRITE (digit,'(I3.3)') e

          rffilename=TRIM(in%wdir)//"/rfaults-"//digit//".vtp"
          CALL exportvtk_rfaults(in%events(e),rffilename)
#endif
          rffilename=TRIM(in%wdir)//"/rfaults-"//digit//".xy"
          CALL exportxy_rfaults(in%events(e),in%x0,in%y0,rffilename)

          PRINT 2000
       END IF
       
       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       !          T E N S I L E      S O U R C E S
       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       PRINT '("# number of coseismic tensile segments")'
       CALL getdata(iunit,dataline)
       READ  (dataline,*) in%events(e)%nt
       PRINT '(I5)', in%events(e)%nt
       IF (in%events(e)%nt .GT. 0) THEN
          ALLOCATE(in%events(e)%ts(in%events(e)%nt),in%events(e)%tsc(in%events(e)%nt), &
               STAT=iostatus)
          IF (iostatus>0) STOP "could not allocate the tensile source list"
          PRINT 2000
          PRINT '("#  n  opening       xs       ys       zs  length   width strike   dip")'
          PRINT 2000
          DO k=1,in%events(e)%nt

             CALL getdata(iunit,dataline)
             READ  (dataline,*) i,in%events(e)%ts(k)%opening, &
                  in%events(e)%ts(k)%x,in%events(e)%ts(k)%y,in%events(e)%ts(k)%z, &
                  in%events(e)%ts(k)%length,in%events(e)%ts(k)%width, &
                  in%events(e)%ts(k)%strike,in%events(e)%ts(k)%dip

             in%events(e)%ts(k)%slip=in%events(e)%ts(k)%opening

             ! copy the input format for display
             in%events(e)%tsc(k)=in%events(e)%ts(k)
             
             PRINT '(I4.4,4ES9.2E1,2ES8.2E1,f7.1,f6.1)',k, &
                  in%events(e)%tsc(k)%opening,&
                  in%events(e)%tsc(k)%x,in%events(e)%tsc(k)%y,in%events(e)%tsc(k)%z, &
                  in%events(e)%tsc(k)%length,in%events(e)%tsc(k)%width, &
                  in%events(e)%tsc(k)%strike,in%events(e)%tsc(k)%dip
             
             IF (i .ne. k) THEN
                PRINT *, "error in input file: source index misfit"
                STOP 1
             END IF
             IF (in%events(e)%ts(k)%length .lt. minlength) THEN
                minlength=in%events(e)%ts(k)%length
             END IF
             IF (in%events(e)%ts(k)%width  .lt. minwidth) THEN
                minwidth =in%events(e)%ts(k)%width
             END IF
             
             ! this is replaced by the exact solution (Okada 1992)
             ! smooth out the slip distribution
             !CALL antialiasingfilter(in%events(e)%ts(k)%slip, &
             !                 in%events(e)%ts(k)%length,in%events(e)%ts(k)%width, &
             !                 in%dx1,in%dx2,in%dx3,in%nyquist)

             ! comply to Wang's convention
             CALL wangconvention(in%events(e)%ts(k)%slip, &
                  in%events(e)%ts(k)%x,in%events(e)%ts(k)%y,in%events(e)%ts(k)%z, &
                  in%events(e)%ts(k)%length,in%events(e)%ts(k)%width, &
                  in%events(e)%ts(k)%strike,in%events(e)%ts(k)%dip,dummy, &
                  in%x0,in%y0,in%rot)

          END DO
#ifdef VTK
          ! export the fault segments in VTK format for the current event
          WRITE (digit,'(I3.3)') e

          rffilename=TRIM(in%wdir)//"/rdykes-"//digit//".vtp"
          CALL exportvtk_rfaults(in%events(e),rffilename)
#endif
          rffilename=TRIM(in%wdir)//"/rdykes-"//digit//".xy"
          CALL exportxy_rfaults(in%events(e),in%x0,in%y0,rffilename)

          PRINT 2000
       END IF
       
       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       !                M O G I      S O U R C E S
       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       PRINT '("# number of dilatation point sources")'
       CALL getdata(iunit,dataline)
       READ  (dataline,*) in%events(e)%nm
       PRINT '(I5)', in%events(e)%nm
       IF (in%events(e)%nm .GT. 0) THEN
          ALLOCATE(in%events(e)%m(in%events(e)%nm),in%events(e)%mc(in%events(e)%nm), &
               STAT=iostatus)
          IF (iostatus>0) STOP "could not allocate the mogi source list"
          PRINT 2000
          PRINT '("#  n strain (positive for extension) xs ys zs")'
          PRINT 2000
          DO k=1,in%events(e)%nm
             CALL getdata(iunit,dataline)
             READ  (dataline,*) i,in%events(e)%m(k)%slip, &
                  in%events(e)%m(k)%x,in%events(e)%m(k)%y,in%events(e)%m(k)%z
             ! copy the input format for display
             in%events(e)%mc(k)=in%events(e)%m(k)
             
             PRINT '(I4.4,4ES9.2E1)',k, &
                  in%events(e)%mc(k)%slip,&
                  in%events(e)%mc(k)%x,in%events(e)%mc(k)%y,in%events(e)%mc(k)%z
             
             IF (i .ne. k) THEN
                PRINT *, "error in input file: source index misfit"
                STOP 1
             END IF
             
             ! rotate the source in the computational reference frame
             CALL rotation(in%events(e)%m(k)%x,in%events(e)%m(k)%y,in%rot)
          END DO
          PRINT 2000
       END IF

       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       !              E I G E N S T R A I N
       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       IF (in%iseigenstrain) THEN
          PRINT '("# number of cuboid eigenstrain sources")'
          CALL getdata(iunit,dataline)
          READ  (dataline,*) in%events(e)%ncuboid
          PRINT '(I5)', in%events(e)%ncuboid
          IF (in%events(e)%ncuboid .GT. 0) THEN
             ALLOCATE(in%events(e)%cuboid(in%events(e)%ncuboid), &
                      in%events(e)%cuboidc(in%events(e)%ncuboid), &
                  STAT=iostatus)
             IF (iostatus>0) STOP "could not allocate the cuboid eigenstrain source list"
             PRINT 2000
             PRINT '("#  n       e11       e12       e13       e22       e23       ", &
                      "e33       x1       x2       x3  length   width thickness strike dip")'
             PRINT 2000
             DO k=1,in%events(e)%ncuboid
                CALL getdata(iunit,dataline)
                READ  (dataline,*) i, &
                     in%events(e)%cuboid(k)%e%s11, &
                     in%events(e)%cuboid(k)%e%s12, &
                     in%events(e)%cuboid(k)%e%s13, &
                     in%events(e)%cuboid(k)%e%s22, &
                     in%events(e)%cuboid(k)%e%s23, &
                     in%events(e)%cuboid(k)%e%s33, &
                     in%events(e)%cuboid(k)%x, &
                     in%events(e)%cuboid(k)%y, &
                     in%events(e)%cuboid(k)%z, &
                     in%events(e)%cuboid(k)%length, &
                     in%events(e)%cuboid(k)%width, &
                     in%events(e)%cuboid(k)%thickness, &
                     in%events(e)%cuboid(k)%strike, &
                     in%events(e)%cuboid(k)%dip

                ! copy the input format for display
                in%events(e)%cuboidc(k)=in%events(e)%cuboid(k)
             
                PRINT '(I4.4,9ES10.2E2,3ES8.2E1,2ES9.2E1)',k, &
                     in%events(e)%cuboidc(k)%e%s11, &
                     in%events(e)%cuboidc(k)%e%s12, &
                     in%events(e)%cuboidc(k)%e%s13, &
                     in%events(e)%cuboidc(k)%e%s22, &
                     in%events(e)%cuboidc(k)%e%s23, &
                     in%events(e)%cuboidc(k)%e%s33, &
                     in%events(e)%cuboidc(k)%x, &
                     in%events(e)%cuboidc(k)%y, &
                     in%events(e)%cuboidc(k)%z, &
                     in%events(e)%cuboidc(k)%length, &
                     in%events(e)%cuboidc(k)%width, &
                     in%events(e)%cuboidc(k)%thickness, &
                     in%events(e)%cuboidc(k)%strike, &
                     in%events(e)%cuboidc(k)%dip
             
                IF (i .ne. k) THEN
                   PRINT *, "error in input file: source index misfit"
                   STOP 1
                END IF
             
                ! comply to Wang's convention
                CALL wangconvention( &
                     dummy, & 
                     in%events(e)%cuboid(k)%x, &
                     in%events(e)%cuboid(k)%y, &
                     in%events(e)%cuboid(k)%z, &
                     in%events(e)%cuboid(k)%length, &
                     in%events(e)%cuboid(k)%width, &
                     in%events(e)%cuboid(k)%strike, &
                     in%events(e)%cuboid(k)%dip, &
                     dummy,in%x0,in%y0,in%rot)

                WRITE (digit,'(I3.3)') k

                ! export the cuboid eigenstrain in GMT .xy format
                !rffilename=TRIM(in%wdir)//"/cuboid-"//digit//".xy"
                !CALL exportxy_brick(in%events(e)%cuboid(k)%x, &
                !                    in%events(e)%cuboid(k)%y, &
                !                    in%events(e)%cuboid(k)%z, &
                !                    in%events(e)%cuboid(k)%length, &
                !                    in%events(e)%cuboid(k)%width, &
                !                    in%events(e)%cuboid(k)%thickness, &
                !                    in%events(e)%cuboid(k)%strike, &
                !                    in%events(e)%cuboid(k)%dip,rffilename)
             END DO
#ifdef VTK
             ! export the cuboid eigenstrain in VTK format
             rffilename=TRIM(in%wdir)//"/cuboid.vtp"
             CALL exportvtk_allbricks(in%events(e)%ncuboid,in%events(e)%cuboid,rffilename)
#endif
             PRINT 2000
          END IF

          IF (in%iscurvilinear) THEN
             PRINT '("# number of distributed tetrahedral eigenstrain sources")'
             CALL getdata(iunit,dataline)
             READ  (dataline,*) in%events(e)%ntetrahedron
             PRINT '(I5)', in%events(e)%ntetrahedron
             IF (in%events(e)%ntetrahedron .GT. 0) THEN
                ALLOCATE(in%events(e)%tetrahedron(in%events(e)%ntetrahedron), &
                     STAT=iostatus)
                IF (iostatus>0) STOP "could not allocate the tetrahedral eigenstrain source list"
                PRINT 2000
                PRINT '("#  n       e11       e12       e13       e22       e23       ", &
                         "e33       i1       i2       i3       i4")'
                PRINT 2000
                DO k=1,in%events(e)%ntetrahedron
                   CALL getdata(iunit,dataline)
                   READ (dataline,*) i, &
                        in%events(e)%tetrahedron(k)%e%s11, &
                        in%events(e)%tetrahedron(k)%e%s12, &
                        in%events(e)%tetrahedron(k)%e%s13, &
                        in%events(e)%tetrahedron(k)%e%s22, &
                        in%events(e)%tetrahedron(k)%e%s23, &
                        in%events(e)%tetrahedron(k)%e%s33, &
                        in%events(e)%tetrahedron(k)%i1, &
                        in%events(e)%tetrahedron(k)%i2, &
                        in%events(e)%tetrahedron(k)%i3, &
                        in%events(e)%tetrahedron(k)%i4

                   PRINT '(I4.4,6ES10.2E2,4(X,I8))',k, &
                        in%events(e)%tetrahedron(k)%e%s11, &
                        in%events(e)%tetrahedron(k)%e%s12, &
                        in%events(e)%tetrahedron(k)%e%s13, &
                        in%events(e)%tetrahedron(k)%e%s22, &
                        in%events(e)%tetrahedron(k)%e%s23, &
                        in%events(e)%tetrahedron(k)%e%s33, &
                        in%events(e)%tetrahedron(k)%i1, &
                        in%events(e)%tetrahedron(k)%i2, &
                        in%events(e)%tetrahedron(k)%i3, &
                        in%events(e)%tetrahedron(k)%i4
             
                   IF (i .ne. k) THEN
                      PRINT *, "error in input file: source index misfit"
                      STOP 1
                   END IF
                END DO

                PRINT '("# number of tetrahedron vertices")'
                CALL getdata(iunit,dataline)
                READ  (dataline,*) in%events(e)%nTetrahedronVertex
                PRINT '(I5)', in%events(e)%nTetrahedronVertex

                ALLOCATE(in%events(e)%tetrahedronVertex(3,in%events(e)%ntetrahedronVertex), &
                     STAT=iostatus)
                IF (iostatus>0) STOP "could not allocate the tetrahedral eigenstrain source list"

                PRINT 2000
                PRINT '("#  n        x1        x2        x3")'
                PRINT 2000
                IF (in%events(e)%nTetrahedronVertex .GT. 0) THEN
                   DO k=1,in%events(e)%nTetrahedronVertex
                      CALL getdata(iunit,dataline)
                      READ (dataline,*) i, &
                           in%events(e)%tetrahedronVertex(1,k), &
                           in%events(e)%tetrahedronVertex(2,k), &
                           in%events(e)%tetrahedronVertex(3,k)

                      PRINT '(I4.4,3ES10.2E2)',k, &
                           in%events(e)%tetrahedronVertex(1,k), &
                           in%events(e)%tetrahedronVertex(2,k), &
                           in%events(e)%tetrahedronVertex(3,k)
             
                      IF (i .ne. k) THEN
                         PRINT *, "error in input file: source index misfit"
                         STOP 1
                      END IF
                   END DO

                ELSE
                   PRINT *, "error in input file: must provide tetrahedra vertices."
                   STOP 1
                END IF

             END IF
          END IF

       END IF

       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       !             S U R F A C E   L O A D S
       ! - - - - - - - - - - - - - - - - - - - - - - - - - -
       PRINT '("# number of surface loads")'
       CALL getdata(iunit,dataline)
       READ  (dataline,*) in%events(e)%nl
       PRINT '(I5)', in%events(e)%nl
       IF (in%events(e)%nl .GT. 0) THEN
          ALLOCATE(in%events(e)%l(in%events(e)%nl),in%events(e)%lc(in%events(e)%nl), &
               STAT=iostatus)
          IF (iostatus>0) STOP "could not allocate the load list"
          PRINT 2000
          PRINT '("# t3 in units of force/surface, positive down")'
          PRINT '("# T>0 for t3 sin(2pi/T+phi), T<=0 for t3 H(t)")'
          PRINT '("#  n       xs       ys   length    width       t3        T      phi")'
          PRINT 2000
          DO k=1,in%events(e)%nl
             CALL getdata(iunit,dataline)
             READ  (dataline,*,IOSTAT=iostatus) i, &
                  in%events(e)%l(k)%x,in%events(e)%l(k)%y, &
                  in%events(e)%l(k)%length,in%events(e)%l(k)%width, &
                  in%events(e)%l(k)%slip, &
                  in%events(e)%l(k)%period,in%events(e)%l(k)%phase, &
                  in%events(e)%l(k)%beta
             
             SELECT CASE(iostatus)
             CASE (1:)
                WRITE_DEBUG_INFO
                WRITE (0,'("invalid surface load definition at line")')
                WRITE (0,'(a)') dataline
                STOP 1
             CASE (0)
                IF (in%events(e)%l(k)%beta.GT.0.5d8) STOP "invalid smoothing parameter beta."
             CASE (:-1)
                ! use default value for smoothing
                in%events(e)%l(k)%beta=in%beta
             END SELECT

             ! copy the input format for display
             in%events(e)%lc(k)=in%events(e)%l(k)

             IF (iostatus.EQ.0) THEN
                PRINT '(I4.4,9ES9.2E1)',k, &
                     in%events(e)%lc(k)%x,in%events(e)%lc(k)%y, &
                     in%events(e)%lc(k)%length,in%events(e)%lc(k)%width, &
                     in%events(e)%lc(k)%slip, &
                     in%events(e)%lc(k)%period,in%events(e)%lc(k)%phase, &
                     in%events(e)%lc(k)%beta
             ELSE
                PRINT '(I4.4,8ES9.2E1)',k, &
                     in%events(e)%lc(k)%x,in%events(e)%lc(k)%y, &
                     in%events(e)%lc(k)%length,in%events(e)%lc(k)%width, &
                     in%events(e)%lc(k)%slip, &
                     in%events(e)%lc(k)%period,in%events(e)%lc(k)%phase
             END IF

             IF (i .NE. k) THEN
                PRINT *, "error in input file: source index misfit"
                STOP 1
             END IF
             
             ! rotate the source in the computational reference frame
             CALL rotation(in%events(e)%l(k)%x,in%events(e)%l(k)%y,in%rot)
          END DO
          PRINT 2000
       END IF
       
    END DO

    ! test the presence of dislocations for coseismic calculation
    IF ((in%events(1)%nt .EQ. 0) .AND. &
        (in%events(1)%ns .EQ. 0) .AND. &
        (in%events(1)%nm .EQ. 0) .AND. &
        (in%events(1)%nl .EQ. 0) .AND. &
        (in%events(1)%nCuboid .EQ. 0) .AND. &
        (in%events(1)%nTetrahedron .EQ. 0) .AND. &
        (in%interval .LE. 0._8)) THEN

       WRITE_DEBUG_INFO
       WRITE (0,'("**** error **** ")')
       WRITE (0,'("no input dislocations or dilatation point sources")')
       WRITE (0,'("or surface tractions for first event . exiting.")')
       STOP 1
    END IF

    ! maximum recommended sampling size
    PRINT '(a,2ES8.2E1)', &
         "# max sampling size (hor.,vert.):", minlength/2.5_8,minwidth/2.5_8

    PRINT 2000

2000 FORMAT ("# ----------------------------------------------------------------------------")
2100 FORMAT ("# n        x1       x2       x3   length    width strike    dip")
2300 FORMAT ("# n name       x1       x2       x3 (name is a 4-character string)")
2500 FORMAT ("# n        x1       x2       x3   length    width strike    dip   rake")

  END SUBROUTINE init

  !------------------------------------------------------------------
  !> subroutine WangConvention
  !! converts a fault slip model from a geologic description including
  !! fault length, width, strike, dip and rake into a description
  !! compatible with internal convention of the program.
  !!
  !! Internal convention describes a fault patch by the location of
  !! its center, instead of an upper corner and its orientation by
  !! the deviation from the vertical, instead of the angle from the
  !! horizontal and by the angle from the x2 axis (East-West)
  !------------------------------------------------------------------
  SUBROUTINE wangconvention(slip,x,y,z,length,width,strike,dip,rake,x0,y0,rot)
    REAL*8, INTENT(OUT) :: slip, x,y,z,strike,dip,rake
    REAL*8, INTENT(IN) :: length,width,x0,y0,rot

    slip=-slip
    strike=-90._8-strike
    dip   = 90._8-dip

    strike=strike*DEG2RAD
    dip=dip*DEG2RAD
    rake=rake*DEG2RAD

    x=x-x0-length/2._8*sin(strike)+width /2._8*sin(dip)*cos(strike)
    y=y-y0-length/2._8*cos(strike)-width /2._8*sin(dip)*sin(strike)
    z=z+width /2._8*cos(dip)

    CALL rotation(x,y,rot)

    strike=strike+rot*DEG2RAD

  END SUBROUTINE wangconvention
  
  !------------------------------------------------------------------
  !> subroutine Rotation
  !! rotates a point coordinate into the computational reference
  !! system.
  !! 
  !! \author sylvain barbot (04/16/09) - original form
  !------------------------------------------------------------------
  SUBROUTINE rotation(x,y,rot)
    REAL*8, INTENT(INOUT) :: x,y
    REAL*8, INTENT(IN) :: rot

    REAL*8 :: alpha,xx,yy

    alpha=rot*DEG2RAD
    xx=x
    yy=y

    x=+xx*cos(alpha)+yy*sin(alpha)
    y=-xx*sin(alpha)+yy*cos(alpha)

  END SUBROUTINE rotation

  !-------------------------------------------------------------------
  !> subroutine AntiAliasingFilter
  !! smoothes a slip distribution model to avoid aliasing of
  !! the source geometry. Aliasing occurs is a slip patch has 
  !! dimensions (width or length) smaller than the grid sampling.
  !!
  !! if a patch length is smaller than a critical size L=dx*nyquist, it 
  !! is increased to L and the slip (or opening) is scaled accordingly
  !! so that the moment M = s*L*W is conserved.
  !!
  !! \author sylvain barbot (12/08/09) - original form
  !-------------------------------------------------------------------
  SUBROUTINE antialiasingfilter(slip,length,width,dx1,dx2,dx3,nyquist)
    REAL*8, INTENT(INOUT) :: slip,length,width
    REAL*8, INTENT(IN) :: dx1,dx2,dx3,nyquist

    REAL*8 :: dx

    ! minimum slip patch dimension
    dx=MIN(dx1,dx2,dx3)*nyquist

    ! update length
    IF (length .LT. dx) THEN
       slip=slip*length/dx
       length=dx
    END IF
    ! update width
    IF (width .LT. dx) THEN
       slip=slip*width/dx
       width=dx
    END IF

  END SUBROUTINE antialiasingfilter

END MODULE input
