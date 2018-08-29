input boxes

vardef drawlink(expr i, j, d) =
  save p, q, r;
  pair p, q, r;
  p = es[i].s;
  q = es[j].s;
  r = .5[p, q] shifted (0, -d);
  drawarrow p .. r .. q;
enddef;

beginfig(1);
  boxjoin(a.ne=b.nw; a.se=b.sw);
  boxit.ss0(btex 5 etex);
  boxit.ss1(btex 1 etex);
  boxit.ss2(btex 5 etex);
  boxit.ss3(btex $\div$ etex);
  boxit.ss4(btex $-$ etex);
  boxit.ss5(btex 5 etex);
  boxit.ss6(btex $\times$ etex);

  boxjoin(a.ne=b.nw; a.se=b.sw);
  boxit.es0(btex 5 etex);
  boxit.es1(btex 1 etex);
  boxit.es2(btex 5 etex);
  boxit.es3(btex $1\over5$ etex);
  boxit.es4(btex $24\over5$ etex);
  boxit.es5(btex 5 etex);
  boxit.es6(btex 24 etex);

  interim defaultdx := 5pt;
  interim defaultdy := 5pt;
  for i = 0 upto 6:
    es[i].nw = ss[i].sw;
    es[i].ne = ss[i].se;
    drawboxed(ss[i], es[i]);
    label.top(decimal(i), ss[i].n);
  endfor
  label.lft(btex Search stack etex, ss0.w);
  label.lft(btex Eval stack etex, es0.w);

  drawlink(5, 4, 3pt);
  drawlink(3, 0, 6pt);
  drawlink(2, 1, 3pt);
  drawlink(1, 0, 3pt);
endfig;

end

% vim: ts=2:sw=2:et
