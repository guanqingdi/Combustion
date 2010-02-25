      subroutine get_temp_visc_terms(scal,beta,visc,dx,time)
      implicit none
      include 'spec.h'
      real*8 scal(-1:nx  ,*)
      real*8 beta(-1:nx  ,*)
      real*8 visc(0 :nx-1)
      real*8 dx, time
      

c     Compute Div(lambda.Grad(T)) + rho.D.Grad(Hi).Grad(Yi)
C CEG:: the first thing rhoDgradHgradY() does is set grow cells
C      call set_bc_grow_s(scal,dx,time)
      call rhoDgradHgradY(scal,beta,visc,dx,time)

c     Add Div( lambda Grad(T) )
      call addDivLambdaGradT(scal,beta,visc,dx,time)

      end

      subroutine addDivLambdaGradT(scal,beta,visc,dx,time)
      implicit none
      include 'spec.h'
      real*8 scal(-1:nx  ,*)
      real*8 beta(-1:nx  ,*)
      real*8 visc(0 :nx-1)
      real*8 dx, time
      
      integer i
      real*8 beta_lo,beta_hi
      real*8 flux_lo,flux_hi
      real*8 dxsqinv


C CEG:: this function will sometimes be called independently from 
C       get_temp_visc_terms, so need this here
      call set_bc_grow_s(scal,dx,time)

      dxsqinv = 1.d0/(dx*dx)
      do i = 0,nx-1
         if (coef_avg_harm.eq.1) then
            beta_lo = 2.d0 / (1.d0/beta(i,Temp)+1.d0/beta(i-1,Temp))
            beta_hi = 2.d0 / (1.d0/beta(i,Temp)+1.d0/beta(i+1,Temp))
         else
            beta_lo = 0.5*(beta(i,Temp) + beta(i-1,Temp))
            beta_hi = 0.5*(beta(i,Temp) + beta(i+1,Temp))
         endif
         
         flux_hi = beta_hi*(scal(i+1,Temp) - scal(i  ,Temp)) 
         flux_lo = beta_lo*(scal(i  ,Temp) - scal(i-1,Temp)) 
         visc(i) = visc(i) + (flux_hi - flux_lo) * dxsqinv

      enddo

 1001 FORMAT(E22.15,1X)      
            

      end

      subroutine rhoDgradHgradY(scal,beta,visc,dx,time)
      implicit none
      include 'spec.h'
      real*8 scal(-1:nx  ,*)
      real*8 beta(-1:nx  ,*)
      real*8 visc(0 :nx-1)
      real*8 dx,time
      
      integer i,n,is,IWRK
      real*8 beta_lo,beta_hi
      real*8 rdgydgh_lo,rdgydgh_hi
      real*8 dxsqinv,RWRK,rho,dv
      real*8 hi(maxspec,-1:nx)
      real*8 Y(maxspec,-1:nx)



CCCCCCCCCCC debugging FIXME
C 1011 FORMAT((I5,1X),2(E22.15,1X))      
C         open(UNIT=11, FILE='tvt.dat', STATUS = 'REPLACE')
CCCCCCCCC

c     Compute rhoD Grad(Yi).Grad(hi) terms

      dxsqinv = 1.d0/(dx*dx)
c     Get Hi, Yi at cell centers
      call set_bc_grow_s(scal,dx,time)
      do i = -1,nx
         rho = 0.d0
         do n=1,Nspec
            rho = rho + scal(i,FirstSpec+n-1)
         enddo
         call CKHMS(scal(i,Temp),IWRK,RWRK,hi(1,i))
         do n=1,Nspec
            Y(n,i) = scal(i,FirstSpec+n-1)/rho
         enddo
      enddo
C      do n = 1,Nspec
C         hi(n,-1) = hi(n,0)
C      enddo

c     Compute differences
      do i = 0,nx-1
         dv = 0.d0
         do n=1,Nspec
            is = FirstSpec + n - 1
            if (coef_avg_harm.eq.1) then
               beta_lo = 2.d0 / (1.d0/beta(i,is)+1.d0/beta(i-1,is))
               beta_hi = 2.d0 / (1.d0/beta(i,is)+1.d0/beta(i+1,is))
            else
               beta_lo = 0.5d0*(beta(i,is) + beta(i-1,is))
               beta_hi = 0.5d0*(beta(i,is) + beta(i+1,is))
            endif
            
            rdgydgh_lo = beta_lo*(Y(n,i)-Y(n,i-1))*(hi(n,i)-hi(n,i-1))
            rdgydgh_hi = beta_hi*(Y(n,i+1)-Y(n,i))*(hi(n,i+1)-hi(n,i))

C$$$CCCCCCCCCCCCCCCCC            
C$$$            write(11,1011) i,Y(n,i),Y(n,i-1)
C$$$            write(11,1011) i,(Y(n,i)-Y(n,i-1)),(hi(n,i)-hi(n,i-1))
C$$$            write(11,1011) i,hi(n,i),hi(n,i-1)
C$$$            write(11,1011) i,scal(i,Temp),scal(i-1,Temp)
C$$$            write(11,*)
CCCCCCCCCCCCCCCCCCc
            dv = dv + (rdgydgh_hi + rdgydgh_lo)*0.5d0
         enddo
         
CCCCCCCCCCCCC
C         write(11,*)
C         write(11,*)
CCCCCCCCCCCCC

         visc(i) = dv*dxsqinv

        end do

CCCCCCCCCCCCCC
C         close(11)
C         write(*,*)'end of step'
C         stop
CCCCCCCCCCCCC      
      end
