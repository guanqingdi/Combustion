      subroutine update_spec(scal_old,scal_new,aofs,alpha,
     $                       dRhs,Rhs,dt,lo,hi,bc)

      implicit none
      include 'spec.h'

      real*8 scal_old(-2:nfine+1,nscal)
      real*8 scal_new(-2:nfine+1,nscal)
      real*8     aofs(0 :nfine-1,nscal)
      real*8    alpha(0 :nfine-1)
      real*8      Rhs(0:nfine-1,Nspec)
      real*8     dRhs(0:nfine-1,Nspec)
      real*8 dt
      integer lo,hi,bc(2)
      
      integer i,n,is

      do i=lo,hi
         do n=1,Nspec
            is = FirstSpec + n - 1
            scal_new(i,is) = scal_old(i,is) + dt*aofs(i,is)
            Rhs(i,n) = dRhs(i,n) + scal_new(i,is)
            alpha(i) = scal_new(i,Density)
         enddo
      enddo

      call set_bc_s(scal_new,lo,hi,bc)

      end


