import math

import numpy as np

def bracket(func, xa=0.0, xb=1.0, args=(), grow_limit=110.0, maxiter=1000):
    """
    Bracket the minimum of the function.
    Given a function and distinct initial points, search in the
    downhill direction (as defined by the initial points) and return
    new points xa, xb, xc that bracket the minimum of the function
    f(xa) > f(xb) < f(xc). It doesn't always mean that obtained
    solution will satisfy xa<=x<=xb.
    Parameters
    ----------
    func : callable f(x,*args)
        Objective function to minimize.
    xa, xb : float, optional
        Bracketing interval. Defaults `xa` to 0.0, and `xb` to 1.0.
    args : tuple, optional
        Additional arguments (if present), passed to `func`.
    grow_limit : float, optional
        Maximum grow limit.  Defaults to 110.0
    maxiter : int, optional
        Maximum number of iterations to perform. Defaults to 1000.
    Returns
    -------
    xa, xb, xc : float
        Bracket.
    fa, fb, fc : float
        Objective function values in bracket.
    funcalls : int
        Number of function evaluations made.
    Examples
    --------
    This function can find a downward convex region of a function:
    >>> import numpy as np
    >>> import matplotlib.pyplot as plt
    >>> from scipy.optimize import bracket
    >>> def f(x):
    ...     return 10*x**2 + 3*x + 5
    >>> x = np.linspace(-2, 2)
    >>> y = f(x)
    >>> init_xa, init_xb = 0, 1
    >>> xa, xb, xc, fa, fb, fc, funcalls = bracket(f, xa=init_xa, xb=init_xb)
    >>> plt.axvline(x=init_xa, color="k", linestyle="--")
    >>> plt.axvline(x=init_xb, color="k", linestyle="--")
    >>> plt.plot(x, y, "-k")
    >>> plt.plot(xa, fa, "bx")
    >>> plt.plot(xb, fb, "rx")
    >>> plt.plot(xc, fc, "bx")
    >>> plt.show()
    """
    _gold = 1.618034  # golden ratio: (1.0+sqrt(5.0))/2.0
    _verysmall_num = 1e-21
    fa = func(*(xa,) + args)
    fb = func(*(xb,) + args)
    if (fa < fb):                      # Switch so fa > fb
        xa, xb = xb, xa
        fa, fb = fb, fa
    xc = xb + _gold * (xb - xa)
    fc = func(*((xc,) + args))
    funcalls = 3
    iter = 0
    while (fc < fb):
        tmp1 = (xb - xa) * (fb - fc)
        tmp2 = (xb - xc) * (fb - fa)
        val = tmp2 - tmp1
        if np.abs(val) < _verysmall_num:
            denom = 2.0 * _verysmall_num
        else:
            denom = 2.0 * val
        w = xb - ((xb - xc) * tmp2 - (xb - xa) * tmp1) / denom
        wlim = xb + grow_limit * (xc - xb)
        if iter > maxiter:
            raise RuntimeError("Too many iterations.")
        iter += 1
        if (w - xc) * (xb - w) > 0.0:
            fw = func(*((w,) + args))
            funcalls += 1
            if (fw < fc):
                xa = xb
                xb = w
                fa = fb
                fb = fw
                return xa, xb, xc, fa, fb, fc, funcalls
            elif (fw > fb):
                xc = w
                fc = fw
                return xa, xb, xc, fa, fb, fc, funcalls
            w = xc + _gold * (xc - xb)
            fw = func(*((w,) + args))
            funcalls += 1
        elif (w - wlim)*(wlim - xc) >= 0.0:
            w = wlim
            fw = func(*((w,) + args))
            funcalls += 1
        elif (w - wlim)*(xc - w) > 0.0:
            fw = func(*((w,) + args))
            funcalls += 1
            if (fw < fc):
                xb = xc
                xc = w
                w = xc + _gold * (xc - xb)
                fb = fc
                fc = fw
                fw = func(*((w,) + args))
                funcalls += 1
        else:
            w = xc + _gold * (xc - xb)
            fw = func(*((w,) + args))
            funcalls += 1
        xa = xb
        xb = xc
        xc = w
        fa = fb
        fb = fc
        fc = fw
    return xa, xb, xc, fa, fb, fc, funcalls

class Brent:
    #need to rethink design of __init__
    def __init__(self, func, args=(), tol=1.48e-8, maxiter=500,
                 full_output=0, disp=0):
        self.func = func
        self.args = args
        self.tol = tol
        self.maxiter = maxiter
        self._mintol = 1.0e-11
        self._cg = 0.3819660
        self.xmin = None
        self.fval = None
        self.iter = 0
        self.funcalls = 0
        self.disp = disp

    # need to rethink design of set_bracket (new options, etc.)
    def set_bracket(self, brack=None):
        self.brack = brack

    def get_bracket_info(self):
        #set up
        func = self.func
        args = self.args
        brack = self.brack
        ### BEGIN core bracket_info code ###
        ### carefully DOCUMENT any CHANGES in core ##
        if brack is None:
            xa, xb, xc, fa, fb, fc, funcalls = bracket(func, args=args)
        elif len(brack) == 2:
            xa, xb, xc, fa, fb, fc, funcalls = bracket(func, xa=brack[0],
                                                       xb=brack[1], args=args)
        elif len(brack) == 3:
            xa, xb, xc = brack
            if (xa > xc):  # swap so xa < xc can be assumed
                xc, xa = xa, xc
            if not ((xa < xb) and (xb < xc)):
                raise ValueError(
                    "Bracketing values (xa, xb, xc) do not"
                    " fulfill this requirement: (xa < xb) and (xb < xc)"
                )
            fa = func(*((xa,) + args))
            fb = func(*((xb,) + args))
            fc = func(*((xc,) + args))
            if not ((fb < fa) and (fb < fc)):
                raise ValueError(
                    "Bracketing values (xa, xb, xc) do not fulfill"
                    " this requirement: (f(xb) < f(xa)) and (f(xb) < f(xc))"
                )

            funcalls = 3
        else:
            raise ValueError("Bracketing interval must be "
                             "length 2 or 3 sequence.")
        ### END core bracket_info code ###

        return xa, xb, xc, fa, fb, fc, funcalls

    def optimize(self):
        # set up for optimization
        func = self.func
        xa, xb, xc, fa, fb, fc, funcalls = self.get_bracket_info()
        print(funcalls)
        _mintol = self._mintol
        _cg = self._cg
        #################################
        #BEGIN CORE ALGORITHM
        #################################
        x = w = v = xb
        fw = fv = fx = fb
        if (xa < xc):
            a = xa
            b = xc
        else:
            a = xc
            b = xa
        deltax = 0.0
        iter = 0

        if self.disp > 2:
            print(" ")
            print(f"{'Func-count':^12} {'x':^12} {'f(x)': ^12}")
            print(f"{funcalls:^12g} {x:^12.6g} {fx:^12.6g}")

        while (iter < self.maxiter):
            tol1 = self.tol * np.abs(x) + _mintol
            tol2 = 2.0 * tol1
            xmid = 0.5 * (a + b)
            # check for convergence
            if np.abs(x - xmid) < (tol2 - 0.5 * (b - a)):
                break
            # XXX In the first iteration, rat is only bound in the true case
            # of this conditional. This used to cause an UnboundLocalError
            # (gh-4140). It should be set before the if (but to what?).
            if (np.abs(deltax) <= tol1):
                if (x >= xmid):
                    deltax = a - x       # do a golden section step
                else:
                    deltax = b - x
                rat = _cg * deltax
            else:                              # do a parabolic step
                tmp1 = (x - w) * (fx - fv)
                tmp2 = (x - v) * (fx - fw)
                p = (x - v) * tmp2 - (x - w) * tmp1
                tmp2 = 2.0 * (tmp2 - tmp1)
                if (tmp2 > 0.0):
                    p = -p
                tmp2 = np.abs(tmp2)
                dx_temp = deltax
                deltax = rat
                # check parabolic fit
                if ((p > tmp2 * (a - x)) and (p < tmp2 * (b - x)) and
                        (np.abs(p) < np.abs(0.5 * tmp2 * dx_temp))):
                    rat = p * 1.0 / tmp2        # if parabolic step is useful.
                    u = x + rat
                    if ((u - a) < tol2 or (b - u) < tol2):
                        if xmid - x >= 0:
                            rat = tol1
                        else:
                            rat = -tol1
                else:
                    if (x >= xmid):
                        deltax = a - x  # if it's not do a golden section step
                    else:
                        deltax = b - x
                    rat = _cg * deltax

            if (np.abs(rat) < tol1):            # update by at least tol1
                if rat >= 0:
                    u = x + tol1
                else:
                    u = x - tol1
            else:
                u = x + rat
            fu = func(*((u,) + self.args))      # calculate new output value
            funcalls += 1

            if (fu > fx):                 # if it's bigger than current
                if (u < x):
                    a = u
                else:
                    b = u
                if (fu <= fw) or (w == x):
                    v = w
                    w = u
                    fv = fw
                    fw = fu
                elif (fu <= fv) or (v == x) or (v == w):
                    v = u
                    fv = fu
            else:
                if (u >= x):
                    a = x
                else:
                    b = x
                v = w
                w = x
                x = u
                fv = fw
                fw = fx
                fx = fu

            if self.disp > 2:
                print(f"{funcalls:^12g} {x:^12.6g} {fx:^12.6g}")

            iter += 1
        #################################
        #END CORE ALGORITHM
        #################################

        self.xmin = x
        self.fval = fx
        self.iter = iter
        self.funcalls = funcalls

    def get_result(self, full_output=False):
        if full_output:
            return self.xmin, self.fval, self.iter, self.funcalls
        else:
            return self.xmin

def brentq(f, xa, xb, xtol, rtol, steps):
    xpre = xa
    xcur = xb
    xblk = 0
    fblk = 0
    spre = 0
    scur = 0
    sbis = 0
    dpre = 0
    dblk = 0

    fpre = f(xpre)
    fcur = f(xcur)
    if fpre*fcur > 0:
        return 0
    if fpre == 0:
        return xpre
    if fcur == 0:
        return xcur

    for i in range(step):
        if fpre*fcur < 0:
            xblk = xpre
            fblk = fpre
            spre = scur = xcur - xpre
        if fabs(fblk) < fabs(fcur):
            xpre = xcur
            xcur = xblk
            xblk = xpre

            fpre = fcur
            fcur = fblk
            fblk = fpre

        delta = (xtol + rtol*abs(xcur))/2
        sbis = (xblk - xcur)/2
        if fcur == 0 or fabs(sbis) < delta:
            return xcur

        if fabs(spre) > delta and fabs(fcur) < fabs(fpre):
            if xpre == xblk:
                stry = -fcur*(xcur - xpre)/(fcur - fpre)
            else:
                dpre = (fpre - fcur)/(xpre - xcur)
                dblk = (fblk - fcur)/(xblk - xcur)
                stry = -fcur*(fblk*dblk - fpre*dpre)/(dblk*dpre*(fblk - fpre))
            if 2*fabs(stry) < min(fabs(spre), 3*fabs(sbis) - delta):
                spre = scur
                scur = stry
            else:
                spre = sbis
                scur = sbis
        else:
            spre = sbis
            scur = sbis

        xpre = xcur
        fpre = fcur
        if abs(scur) > delta:
            xcur += scur
        else:
            xcur += delta if sbis > 0 else -delta
        fcur = f(xcur)
    return xcur;


def local_min(a, b, epsi, t, f):
  c = 0.5 * (3.0 - math.sqrt(5.0))

  sa = a
  sb = b
  x = sa + c * ( b - a )
  w = x
  v = w
  e = 0.0
  fx = f ( x )
  fw = fx
  fv = fw

  while True:
    #print((sa, sb))
    m = 0.5 * (sa + sb)
    tol = epsi * abs(x) + t
    t2 = 2.0 * tol
    if ( abs ( x - m ) <= t2 - 0.5 * ( sb - sa ) ):
      break
    r = 0.0
    q = r
    p = q

    if tol < abs(e):

      r = (x - w) * (fx - fv)
      q = (x - v) * (fx - fw)
      p = (x - v) * q - (x - w) * r
      q = 2.0 * (q - r)

      if 0.0 < q:
        p = - p

      q = abs(q)

      r = e
      e = d

    if (abs(p) < abs(0.5 * q * r) and 
         q * (sa - x) < p and 
         p < q * (sb - x)):
      d = p / q
      u = x + d
      if (u - sa) < t2 or (sb - u) < t2:
        if x < m:
          d = tol
        else:
          d = - tol
    else:
      if x < m:
        e = sb - x
      else:
        e = sa - x

      d = c * e

    if tol <= abs(d):
      u = x + d
    elif 0.0 < d:
      u = x + tol
    else:
      u = x - tol

    fu = f(u)
    if fu <= fx:

      if u < x:
        sb = x
      else:
        sa = x

      v = w
      fv = fw
      w = x
      fw = fx
      x = u
      fx = fu

    else:

      if u < x:
        sa = u
      else:
        sb = u

      if fu <= fw or w == x:
        v = w
        fv = fw
        w = u
        fw = fu
      elif fu <= fv or v == x or v == w:
        v = u
        fv = fu

  return x, fx

def g(f, x, fx):
    """First-order divided difference function.

    Arguments:
        f: Function input to g
        x: Point at which to evaluate g
        fx: Function f evaluated at x 
    """
    return lambda x: f(x + fx) / fx - 1

def steff(f, x):
    """Steffenson algorithm for finding roots.

    This recursive generator yields the x_{n+1} value first then, when the generator iterates,
    it yields x_{n+2} from the next level of recursion.

    Arguments:
        f: Function whose root we are searching for
        x: Starting value upon first call, each level n that the function recurses x is x_n
    """
    i = 0
    print('ok')
    while i < 20:    
        i += 1
        fx = f(x)
        gx = g(f, x, fx)(x)
        print('%s %s %s' % (x, fx, gx))
        if abs(gx) < 1e-10:
            break
        else:
            x = x - fx / gx
            if abs(fx - x) < 1e-10:
                break

def the_func(x):
    f = x**4 - 2*x*x -9*x + 8
    #print('func: {} {}'.format(x, f))
    return f

if __name__ == '__main__':
    print('hi')
    x, f = local_min(-2, 2, 1e-12, 1e-10, the_func)
    print((x, f))

    #steff(the_func, x - 0.1)

    print(brentq(the_func, -5, 5, 1e-8, 1e-12, 10))
    brent = Brent(the_func, tol=1.48e-8, maxiter=500, full_output=0, disp=3)
    brent.set_bracket((-5, 5))
    brent.optimize()
    print(brent.get_result())

