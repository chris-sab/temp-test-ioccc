int main(int t, char **q, char **d) { return cain(t, (int)q, (int)d); }
#define G(n) int n(int t, int q, int d)
#define X(p,t,s) (p>=t&&p<(t+s)&&(p-(t)&1023)<(s&1023))
#define U(m) *((signed char *)(m))
#define F if(!--q){
#define I(s) (int)cain-(int)s
#define P(s,c,k) for(h=0; h>>14==0; h+=129)Y(16*c+h/1024+Y(V+36))&128>>(h&7)?U(s+(h&15367))=k:k

G (B)
{
  Z;
  F D = E (Y (V), C = E (Y (V), Y (t + 4) + 3, 4, 0), 2, 0);
  Y (t + 12) = Y (t + 20) = i;
  Y (t + 24) = 1;
  Y (t + 28) = t;
  Y (t + 16) = 442890;
  Y (t + 28) = d = E (Y (V), s = D * 8 + 1664, 1, 0);
  for (p = 0; j < s; j++, p++)
    U (d + j) = i == D | j < p ? p--, 0 : (n = U (C + 512 + i++)) < ' ' ? p |=
      n * 56 - 497, 0 : n;
}

n = Y (Y (t + 4)) & 1;
F
U (Y (t + 28) + 1536) |=
62 & -n;
M
U (d + D) =
X (D, Y (t + 12) + 26628, 412162) ? X (D, Y (t + 12) + 27653,
				       410112) ? 31 : 0 : U (d + D);
for (; j < 12800; j += 8)
  P (d + 27653 + Y (t + 12) + ' ' * (j & ~511) + j % 512,
     U (Y (t + 28) + j / 8 + 64 * Y (t + 20)), 0);
}

F if (n)
  {
    D = Y (t + 28);
    if (d - 10)
      U (++Y (t + 24) + D + 1535) = d;
    else
      {
	for (i = D; i < D + 1600; i++)
	  U (i) = U (i + 64);
	Y (t + 24) = 1;
	E (Y (V), i - 127, 3, 0);
      }
  }
else
  Y (t + 20) += ((d >> 4) ^ (d >> 5)) - 3;
}
}

G (_);
G (o);
G (cain)
{
  Z, k = K;
  if (!t)
    {
      Y (V) = V + 208 - (I (_));
      L (209, 223) L (168, 0) L (212, 244) _((int) &s, 3, 0);
      for (; 1;)
	R n = Y (V - 12);
      if (C & ' ')
	{
	  k++;
	  k %= 3;
	  if (k < 2)
	    {
	      Y (j) -= p;
	      Y (j) += p += U (&D) * (1 - k * 1025);
	      if (k)
		goto y;
	    }
	  else
	    {
	      for (C = V - 20;
		   !i && D & 1 && n
		   && (X (p, Y (n + 12), Y (n + 16)) ? j = n + 12, Y (C + 8) =
		       Y (n + 8), Y (n + 8) = Y (V - 12), Y (V - 12) =
		       n, 0 : n); C = n, n = Y (n + 8));
	      i = D & 1;
	      j &= -i;
	    }
	}
      else if (128 & ~D)
	{
	  E (Y (n), n, 3, U (V + D % 64 + 131) ^ 32);
	  n = Y (V - 12);
	y:C = 1 << 24;
	  M U (C + D) = 125;
	  o (n, 0, C);
	  P (C + p - 8196, 88, 0);
	  M U (Y (0x11028) + D) = U (C + D);
	}
    }
}

for (D = 720; D > -3888; D--)
  putchar (D >
	   0 ?
	   "  )!\320\234\360\256\370\256 0\230F           .,mnbvcxz    ;lkjhgfdsa \n][poiuytrewq  =-0987654321   \357\262   \337\337 \357\272   \337\337         ( )\"\343\312F\320!/ !\230 26!/\16 K>!/\16\332 \4\16\251\0160\355&\2271\20\2300\355`x{0\355\347\2560 \237qpa%\231o!\230 \337\337\337     ,               )\"K\240   \343\316qrpxzy\0 sRDh\16\313\212u\343\314qrzy    !0( "
	   [D] ^ 32 : Y (I (D)));
return 0;
}

G (o)
{
  Z;
  if (t)
    {
      C = Y (t + 12);
      j = Y (t + 16);
      o (Y (t + 8), 0, d);
      M U (d + D) =
	X (D, C, j) ? X (D, C + 1025, j - 2050) ? X (D, C + 2050,
						     j - 3075) ? X (D,
								    C + 2050,
								    j -
								    4100) ?
	X (D, C + 4100,
	   ((j & 1023) + 18424)) ? 176 : 24 : 20 : 28 : 0 : U (d + D);
      for (n = Y (t + 4); U (i + n); i++)
	P (d + Y (t + 12) + 5126 + i * 8, U (n + i), 31);
      E (Y (t), t, 2, d);
    }
}

G (_)
{
  Z = Y (V + 24);
  F Y (V - 16) += t;
  D = Y (V - 16) - t;
}

F for (i = 124; i < 135; i++)
  D = D << 3 | Y (t + i) & 7;
}

if (q > 0)
  {
    for (; n = U (D + i); i++)
      if (n - U (t + i))
	{
	  D += _(D, 2, 0) + 1023 & ~511;
	  i = ~0;
	}
    F if (Y (D))
      {
	n = _(164, 1, 0);
	Y (n + 8) = Y (V - 12);
	Y (V - 12) = n;
	Y (n + 4) = i = n + 64;
	for (; j < 96; j++)
	  Y (i + j) = Y (t + j);
	i = D + 512;
	j = i + Y (i + 32);
	for (; Y (j + 12) != Y (i + 24); j += 40);
	E (Y (n) = Y (j + 16) + i, n, 1, 0);
      }
  }
}

return D;
}
