
! *****************************COPYRIGHT*******************************
! (C) Crown copyright Met Office. All rights reserved.
! For further details please refer to the file COPYRIGHT.txt
! which you should have received as part of this distribution.
! *****************************COPYRIGHT*******************************
!  SUBROUTINES SFL_INT-----------------------------------------------
!
!  Purpose: To calculate interpolation coefficients for 10m winds
!           and 1.5m temperature/specific humidity diagnostics.
!
!  External Documentation: UMDP No.24
!
!---------------------------------------------------------------------
!    Arguments :-
SUBROUTINE sfl_int (                                              &
 row_length,rows,off_x,off_y,points,tile_pts,                     &
 tile_index,pts_index,fld_sea                                     &
,vshr,cd_std,cd,ch,tile_frac                                      &
,z0m,z0m_std,z0h                                                  &
,recip_l_mo,v_s,v_s_std                                           &
,z1_uv,z1_tq,db                                                   &
,su10,sv10,st1p5,sq1p5                                            &
,cdr10m,chr1p5m,ltimer )

USE c_vkman
USE surf_param, ONLY :                                            &
                eff_int,z_obs_tq, z_obs_wind, ip_scrn_decpl_1
USE switches, ONLY :                                              &
                iscrntdiag

USE parkind1, ONLY: jprb, jpim
USE yomhook, ONLY: lhook, dr_hook
IMPLICIT NONE

INTEGER                                                           &
 row_length                                                       &
                      ! IN Number of X points?
,rows                                                             &
                      ! IN Number of Y points?
,off_x                                                            &
                      ! Size of small halo in i.
,off_y                                                            &
                      ! Size of small halo in j.
,points                                                           &
                      ! IN Number of points.
,tile_pts                                                         &
                      ! IN Number of tile points.
,tile_index(points)                                               &
                      ! IN Index of tile points.
,pts_index(points)    ! IN Index of points.


REAL                                                              &
 fld_sea(row_length,rows)                                         &
!                           ! IN Fraction of land or sea
,z0m(points)                                                      &
                      ! IN Roughness length for momentum (m).
,z0h(points)                                                      &
                      ! IN Roughness length for heat and
!                         !    moisture (m).
,z0m_std(points)                                                  &
                      ! IN Roughness length for momentum without
!                         !    orographic component (m).
,vshr(row_length,rows)                                            &
                      ! IN Wind speed difference between the
!                           !    surface and the lowest wind level in
!                           !    the atmosphere (m/s).
,cd(points)                                                       &
                    ! IN Surface drag coefficient.
,ch(points)                                                       &
                    ! IN Surface transfer coefficient for heat and
!                         !    moisture.
,cd_std(points)                                                   &
                    ! IN Surface drag coefficient excluding
!                         !    orographic from drag.
,tile_frac(points)                                                &
!                         ! IN Tile fraction.
,recip_l_mo(points)                                               &
!                        ! IN Reciprocal of the Monin-Obukhov length (m)
,v_s(points)                                                      &
                    ! IN Surface layer scaling velocity including
!                         !    orographic form drag (m/s).
,v_s_std(points)                                                  &
!                         ! IN Surface layer scaling velocity excluding
!                         !    orographic form drag (m/s).
,z1_tq(row_length,rows)                                           &
!                         ! IN Height of lowest TQ level (m).
,z1_uv(row_length,rows)                                           &
!                         ! IN Height of lowest UV level (m).
,db(points)         ! IN Buoyancy difference between
!                         !    surface and lowest atmospheric
!                         !    level

LOGICAL                                                           &
 su10                                                             &
                           ! IN 10m U-wind diagnostic flag
,sv10                                                             &
                           ! IN 10m V-wind diagnostic flag
,st1p5                                                            &
                           ! IN screen temp diagnostic flag
,sq1p5                                                            &
                           ! IN screen specific humidity
!                                !    diagnostic flag
,ltimer                    ! IN TIMER diagnostics flag
! Output variables

REAL                                                              &
 cdr10m(1-off_x:row_length+off_x,1-off_y:rows+off_y)              &
!                        ! OUT interpolation coefficicent for 10m wind
,chr1p5m(points)   ! OUT Interpolation coefficient for 1.5m
!                        !     temperature

!*
!  ---------------------------------------------------------------------


!  External routines called :-
EXTERNAL phi_m_h
EXTERNAL timer

!*
!  ---------------------------------------------------------------------
!  Define local storage.

!  (a) Local work arrays.

REAL                                                              &
 z_wind(row_length,rows)                                          &
                         ! Height of wind observations.
,z_temp(row_length,rows)                                          &
                         ! Height of temperature and humidity
!                              ! observations.
,phi_m_obs(points)                                                &
                      ! Monin-Obukhov stability function for
!                           ! momentum integrated to the wind observatio
!                           ! height.
,phi_h_obs(points)    ! Monin-Obukhov stability function for
!                           ! scalars integrated to their observation
!                           ! height.

!  (b) Scalars.

INTEGER                                                           &
 i,j,k,l       ! Loop counter (horizontal field index).
REAL                                                              &
   rib             ! Bulk Richardson number of lowest layer

INTEGER(KIND=jpim), PARAMETER :: zhook_in  = 0
INTEGER(KIND=jpim), PARAMETER :: zhook_out = 1
REAL(KIND=jprb)               :: zhook_handle

!*
IF (lhook) CALL dr_hook('SFL_INT',zhook_in,zhook_handle)
IF (ltimer) THEN
! DEPENDS ON: timer
  CALL timer('SFL_INT   ',3)
END IF

!-----------------------------------------------------------------------
!! 1. If diagnostics required calculate M-O stability functions at
!!    observation heights.
!-----------------------------------------------------------------------

! initialise work arrays
z_wind(:,:)  = 0.0
z_temp(:,:)  = 0.0
phi_m_obs(:) = 0.0
phi_h_obs(:) = 0.0

IF (su10 .OR. sv10 .OR. st1p5 .OR. sq1p5) THEN
  DO k=1,tile_pts
    l = tile_index(k)
    j=(pts_index(l)-1)/row_length + 1
    i = pts_index(l) - (j-1)*row_length
    z_wind(i,j) = z_obs_wind
    z_temp(i,j) = z_obs_tq + z0h(l) - z0m(l)
  END DO
! DEPENDS ON: phi_m_h
  CALL phi_m_h (row_length,rows,points,tile_pts,                  &
                tile_index,pts_index,                             &
                recip_l_mo,z_wind,z_temp,z0m,z0h,                 &
                phi_m_obs,phi_h_obs,ltimer)
END IF

!-----------------------------------------------------------------------
!! 2. If diagnostics required calculate interpolation coefficient
!!    for 1.5m screen temperature and specific humidity.
!-----------------------------------------------------------------------

IF (st1p5 .OR. sq1p5) THEN

!       Calculate the screen temperature allowing for decoupling or
!       using pure surface similarity theory as the default. Seperate
!       blocks of code are used for efficiency.

  IF (iscrntdiag == ip_scrn_decpl_1) THEN

    DO k=1,tile_pts
      l = tile_index(k)
      j=(pts_index(l)-1)/row_length + 1
      i = pts_index(l) - (j-1)*row_length
      rib = ( z1_uv(i,j) * z1_uv(i,j) * db(l) ) /                 &
            ( z1_tq(i,j) * vshr(i,j) * vshr(i,j) )
      IF (rib> 0.25) THEN
!             Allow for decoupling in very stable conditions
!             based on the quasi-equilibrium radiative solution.
!             Note: This value is set for a screen level of 1.5m
!             and has been fitted for the bottomlevel lying between
!             1.5 and 20m. It should be recalibrated for coarser
!             resolutions.
        chr1p5m(l) = 0.335+1.78/z1_tq(i,j)-1.19/z1_tq(i,j)**2
      ELSE
!             Use pure surface similarity theory
        chr1p5m(l) = ch(l) * vshr(i,j) *                          &
                      phi_h_obs(l)/(vkman*v_s_std(l))
      END IF
    END DO

  ELSE

    DO k=1,tile_pts
      l = tile_index(k)
      j=(pts_index(l)-1)/row_length + 1
      i = pts_index(l) - (j-1)*row_length
      chr1p5m(l) = ch(l) * vshr(i,j) *                            &
                    phi_h_obs(l)/(vkman*v_s_std(l))

    END DO

  END IF

END IF

!-----------------------------------------------------------------------
!! 3. If diagnostics required calculate interpolation coefficient
!!    for 10m winds.
!-----------------------------------------------------------------------

IF ( (su10 .OR. sv10) .AND. eff_int ) THEN
  DO k=1,tile_pts
    l = tile_index(k)
    j=(pts_index(l)-1)/row_length + 1
    i = pts_index(l) - (j-1)*row_length
    cdr10m(i,j) = cdr10m(i,j) + fld_sea(i,j) * tile_frac(l) *     &
              cd(l) * vshr(i,j) * phi_m_obs(l)/(vkman*v_s(l))
  END DO
ELSE IF ( (su10 .OR. sv10) .AND. .NOT.eff_int ) THEN
  DO k=1,tile_pts
    l = tile_index(k)
    j=(pts_index(l)-1)/row_length + 1
    i = pts_index(l) - (j-1)*row_length
    z_temp(i,j) = z_obs_tq + z0h(l) - z0m_std(l)
  END DO
! DEPENDS ON: phi_m_h
  CALL phi_m_h (row_length,rows,points,tile_pts,                  &
                tile_index,pts_index,                             &
                recip_l_mo,z_wind,z_temp,z0m_std,z0h,             &
                phi_m_obs,phi_h_obs,ltimer)
  DO k=1,tile_pts
    l = tile_index(k)
    j=(pts_index(l)-1)/row_length + 1
    i = pts_index(l) - (j-1)*row_length
    cdr10m(i,j) = cdr10m(i,j) + fld_sea(i,j) * tile_frac(l) *     &
                cd_std(l) * vshr(i,j) * phi_m_obs(l)/             &
                     (vkman*v_s_std(l))
  END DO
END IF

IF (ltimer) THEN
! DEPENDS ON: timer
  CALL timer('SFL_INT ',4)
END IF
IF (lhook) CALL dr_hook('SFL_INT',zhook_out,zhook_handle)
RETURN
END SUBROUTINE sfl_int
