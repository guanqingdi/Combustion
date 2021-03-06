import t
from math import *
import matplotlib.pyplot as plt

a = 0.0
d = -3.0
r = 1.0

def method_str(m):
    if m==0:
        return 'Piecewise Constants'
    elif m==1:
        return 'Piecewise Linears'
    elif m==2:
        return 'Standard MISDC'

def method_marker(m):
    if m==0:
        return '.'
    elif m==1:
        return '*'
    elif m==2:
        return 'o'

misdc_iters = [1, 5, 10, 20, 50, 1000]

dts = [0.125]
for j in range(10):
    dts.append(dts[j]/2)

fig = plt.figure(1, figsize=(10,6))

E = []
for method in [0]:
    print method_str(method)
    for n in misdc_iters:
        e = []
        for dt in dts:
            e.append(t.solve_it(a, d, r, dt, max_iter=n, method=method))
        E.append(e)
        
        for i in range(len(e)-1):
            if e[i+1] > 0 and e[i] > 0:
                print 'iters: ', n, 'order: ', log(e[i+1]/e[i])/log(dts[i+1]/dts[i])
            else:
		print 'iters: ', n, 'order:  ---'
        
        plt.loglog(dts, e, label=str(n)+' '+ method_str(method),
                           marker=method_marker(method))

fig.subplots_adjust(right=0.6)

plt.xlabel('dt')
plt.ylabel('L^1 error')
plt.legend(loc=2, bbox_to_anchor=(1.0,0.8))
plt.show()
