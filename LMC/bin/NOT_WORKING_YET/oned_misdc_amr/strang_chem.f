      subroutine strang_chem(scal_old,scal_new,
     $                       const_src,lin_src_old,lin_src_new,
     $                       I_R,dt,dx,time)
      implicit none
      include 'spec.h'
      real*8     scal_old(-1:nx  ,nscal)
      real*8     scal_new(-1:nx  ,nscal)
      real*8    const_src( 0:nx-1,nscal)
      real*8  lin_src_old( 0:nx-1,nscal)
      real*8  lin_src_new( 0:nx-1,nscal)
      real*8          I_R( 0:nx-1,0:maxspec)
      real*8  dt,dx,time
      
      integer i,is,n,ifail
      real*8 RYold(maxspec), RYnew(maxspec), Told, Tnew
      real*8 rho_old
      integer FuncCount, do_diag
      real*8 diag(maxreac),hmix
      real*8 Y(maxspec)
      
      integer NiterMAX, Niter
      parameter (NiterMAX = 30)
      double precision res(NiterMAX), errMAX

c     Shut off diagnostics
      do_diag = 0

      if (nochem_hack) then
         write(*,*)'WARNING! nochem_hack--skipping reactions'
         return
      endif

      print *,'... chemistry'
c     Evolve chem over grid
      do i = 0,nx-1

C CEG:: done to mimick john's SNe code.  firstSpec should be the fuel (i think)
C I don't think this is appropriate for the more complex reactions network here
C$$$         if (scal_new(i,FirstSpec) .le. 0.d0) then
C$$$            do n = 1, nscal
C$$$               scal_new(i,n) = scal_old(i,n)+
C$$$     &              + dt*const_src(i,n)
C$$$     &              + 0.5d0*dt*(lin_src_old(i,n)+lin_src_new(i,n))
C$$$            enddo
C$$$            do n = 0,Nspec
C$$$               I_R(i,n) = 0.d0
C$$$            enddo
C$$$         else
         if (use_strang) then
C           integrating Y_m's not rhoY_m
            do n = 1,Nspec
               RYold(n) = scal_old(i,FirstSpec+n-1)/scal_old(i,Density)
            enddo
            Told = scal_old(i,Temp)            

         else 

            rho_old = 0.d0
            do n = 1,Nspec
               RYold(n) = scal_old(i,FirstSpec+n-1)
               rho_old = rho_old + RYold(n)
            enddo
            
            Told = scal_old(i,RhoH)

c     Set linear source terms in common for ode integrators access
            do n = 1,Nspec
               is = FirstSpec + n - 1
               c_0(n) = const_src(i,is) + lin_src_old(i,is)
               c_1(n) = (lin_src_new(i,is) - lin_src_old(i,is))/dt
            enddo
            c_0(0) = const_src(i,RhoH) + lin_src_old(i,RhoH)
            c_1(0) = (lin_src_new(i,RhoH) - lin_src_old(i,RhoH))/dt
            rhoh_INIT = scal_old(i,RhoH)
            T_INIT = scal_old(i,Temp)
         endif

         call chemsolve(RYnew, Tnew, RYold, Told, FuncCount, dt,
     &                  diag, do_diag, ifail, i)
         if (ifail.ne.0) then
            print *,'solve failed, i=',i
            stop
         endif

         if(use_strang) then

            do n = 1,Nspec
               scal_new(i,FirstSpec+n-1) = RYnew(n)*scal_old(i,Density)
            enddo
            scal_new(i,Temp) = Tnew
            do n = 1,Nspec
               is = FirstSpec + n - 1
               I_R(i,n) = (scal_new(i,is)-scal_old(i,is)) / dt
            enddo

         else

            scal_new(i,Density) = 0.d0
            do n = 1,Nspec
               scal_new(i,Density) = scal_new(i,Density) + RYnew(n)
            enddo
            do n = 1,Nspec
               scal_new(i,FirstSpec+n-1) = RYnew(n)
               Y(n) = RYnew(n)/scal_new(i,Density)
            enddo

            scal_new(i,RhoH) = Tnew
            hmix = scal_new(i,RhoH) / scal_new(i,Density)
            errMax = hmix_TYP*1.e-20

            call FORT_TfromHYpt(scal_new(i,Temp),hmix,Y,
     &                          Nspec,errMax,NiterMAX,res,Niter)

            if (Niter.lt.0) then
               print *,'strang_chem: H to T solve failed'
               print *,'Niter=',Niter
               stop
            endif

            do n = 1,Nspec
               is = FirstSpec + n - 1
               I_R(i,n) =
     $              (scal_new(i,is)-scal_old(i,is)) / dt
     $              - const_src(i,is)
     $              - 0.5d0*(lin_src_old(i,is)+lin_src_new(i,is))
            enddo

         endif

         call set_bc_s(scal_new,dx,time)

      enddo

      end
