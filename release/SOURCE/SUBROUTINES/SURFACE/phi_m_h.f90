
! *****************************COPYRIGHT*******************************
! (C) Crown copyright Met Office. All rights reserved.
! For further details please refer to the file COPYRIGHT.txt
! which you should have received as part of this distribution.
! *****************************COPYRIGHT*******************************
!   SUBROUTINE PHI_M_H ----------------------------------------------

!  Purpose: Calculate the integrated froms of the Monin-Obukhov
!           stability functions for surface exchanges.

!  Documentation: UM Documentation Paper No 24.

!--- Arguments:---------------------------------------------------------
SUBROUTINE phi_m_h (                                              &
 row_length,rows,points,tile_pts,tile_index,pts_index,            &
 recip_l_mo,z_uv,z_tq,z0m,z0h,phi_m,phi_h,ltimer )

USE surf_param, ONLY : a,b,c,d,c_over_d

USE parkind1, ONLY: jprb, jpim
USE yomhook, ONLY: lhook, dr_hook
IMPLICIT NONE

INTEGER                                                           &
 row_length                                                       &
                      ! IN Number of X points?
,rows                                                             &
                      ! IN Number of Y points?
,points                                                           &
                      ! IN Number of points.
,tile_pts                                                         &
                      ! IN Number of tile points.
,tile_index(points)                                               &
                      ! IN Index of tile points.
,pts_index(points)    ! IN Index of points.

LOGICAL                                                           &
 ltimer


REAL                                                              &
 recip_l_mo(points)                                               &
!                       ! IN Reciprocal of the Monin-Obukhov length
!                       !     (m^-1).
,z_uv(row_length,rows)                                            &
!                       ! IN Height of wind level above roughness
!                       !    height (m)
,z_tq(row_length,rows)                                            &
!                       ! IN Height of temperature, moisture and scalar
!                       !    lev above the roughness height (m).
,z0m(points)                                                      &
                  ! IN Roughness length for momentum (m).
,z0h(points)    ! IN Roughness length for heat/moisture/scalars
!                       !    (m)

REAL                                                              &
 phi_m(points)                                                    &
                  ! OUT Stability function for momentum.
,phi_h(points)  ! OUT Stability function for
!                       !     heat/moisture/scalars.

!    Workspace usage----------------------------------------------------
!    No work areas are required.

!*----------------------------------------------------------------------
!    External subprograms called:

EXTERNAL timer


!  Define local variables.

INTEGER i,j,k,l   ! Loop counter; horizontal field index.

REAL                                                              &
 phi_mn                                                           &
                ! Neutral value of stability function for momentum
,phi_hn                                                           &
                ! Neutral value of stability function for scalars.
,zeta_uv                                                          &
                ! Temporary in calculation of PHI_M.
,zeta_0m                                                          &
                ! Temporary in calculation of PHI_M.
,zeta_tq                                                          &
                ! Temporary in calculation of PHI_H.
,zeta_0h                                                          &
                ! Temporary in calculation of PHI_H.
,x_uv_sq                                                          &
                ! Temporary in calculation of PHI_M.
,x_0m_sq                                                          &
                ! Temporary in calculation of PHI_M.
,x_uv                                                             &
                ! Temporary in calculation of PHI_M.
,x_0m                                                             &
                ! Temporary in calculation of PHI_M.
,y_tq                                                             &
                ! Temporary in calculation of PHI_H.
,y_0h                                                             &
                ! Temporary in calculation of PHI_H.
,phi_h_fz1                                                        &
                ! Temporary in calculation of PHI_H.
,phi_h_fz0      ! Temporary in calculation of PHI_H.

INTEGER(KIND=jpim), PARAMETER :: zhook_in  = 0
INTEGER(KIND=jpim), PARAMETER :: zhook_out = 1
REAL(KIND=jprb)               :: zhook_handle

IF (lhook) CALL dr_hook('PHI_M_H',zhook_in,zhook_handle)

IF (ltimer) THEN
! DEPENDS ON: timer
  CALL timer('PHI_M_H ',3)
END IF

phi_m = 0. !Jupp
phi_h = 0. !Jupp

!CDIR NODEP
DO k=1,tile_pts
  l = tile_index(k)
  j=(pts_index(l)-1)/row_length + 1
  i = pts_index(l) - (j-1)*row_length

!-----------------------------------------------------------------------
!! 1. Calculate neutral values of PHI_M and PHI_H.
!-----------------------------------------------------------------------

  phi_mn = LOG( (z_uv(i,j) + z0m(l)) / z0m(l) )
  phi_hn = LOG( (z_tq(i,j) + z0m(l)) / z0h(l) )

!-----------------------------------------------------------------------
!! 2. Calculate stability parameters.
!-----------------------------------------------------------------------

  zeta_uv = (z_uv(i,j) + z0m(l)) * recip_l_mo(l)
  zeta_tq = (z_tq(i,j) + z0m(l)) * recip_l_mo(l)
  zeta_0m = z0m(l) * recip_l_mo(l)
  zeta_0h = z0h(l) * recip_l_mo(l)

!-----------------------------------------------------------------------
!! 3. Calculate PHI_M and PHI_H for neutral and stable conditions.
!!    Formulation of Beljaars and Holtslag (1991).
!-----------------------------------------------------------------------

  IF (recip_l_mo(l)  >=  0.0) THEN
    phi_m(l) = phi_mn                                             &
               + a * (zeta_uv - zeta_0m)                          &
               + b * ( (zeta_uv - c_over_d) * EXP(-d*zeta_uv)     &
                      -(zeta_0m - c_over_d) * EXP(-d*zeta_0m) )
    phi_h_fz1 = SQRT(1.0 + (2.0/3.0)*a*zeta_tq)
    phi_h_fz0 = SQRT(1.0 + (2.0/3.0)*a*zeta_0h)
    phi_h(l) = phi_hn +                                           &
                 phi_h_fz1*phi_h_fz1*phi_h_fz1                    &
               - phi_h_fz0*phi_h_fz0*phi_h_fz0                    &
               + b * ( (zeta_tq - c_over_d) * EXP(-d*zeta_tq)     &
                      -(zeta_0h - c_over_d) * EXP(-d*zeta_0h) )

!-----------------------------------------------------------------------
!! 4. Calculate PHI_M and PHI_H for unstable conditions.
!-----------------------------------------------------------------------

  ELSE

    x_uv_sq = SQRT(1.0 - 16.0*zeta_uv)
    x_0m_sq = SQRT(1.0 - 16.0*zeta_0m)
    x_uv = SQRT(x_uv_sq)
    x_0m = SQRT(x_0m_sq)
    phi_m(l) = phi_mn - 2.0*LOG( (1.0+x_uv) / (1.0+x_0m) )        &
                    - LOG( (1.0+x_uv_sq) / (1.0+x_0m_sq) )        &
                    + 2.0*( ATAN(x_uv) - ATAN(x_0m) )

    y_tq = SQRT(1.0 - 16.0*zeta_tq)
    y_0h = SQRT(1.0 - 16.0*zeta_0h)
    phi_h(l) = phi_hn - 2.0*LOG( (1.0+y_tq) / (1.0+y_0h) )

  END IF

END DO

IF (ltimer) THEN
! DEPENDS ON: timer
  CALL timer('PHI_M_H ',4)
END IF

IF (lhook) CALL dr_hook('PHI_M_H',zhook_out,zhook_handle)
RETURN
END SUBROUTINE phi_m_h
