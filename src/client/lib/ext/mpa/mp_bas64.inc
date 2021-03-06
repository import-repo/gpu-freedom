{Basic 64 bit routines}

{---------------------------------------------------------------------------}
function bitsize32(a: longint): integer;
  {-return the number of bits in a (index of highest bit), 0 if no bit is set}
var
  x: word;
  r: integer;
type
  LH = packed record L,H: word; end;
begin
  if LH(a).H<>0 then begin
    x := LH(a).H;
    r := 16;
  end
  else begin
    x := LH(a).L;
    r := 0;
  end;
  if x<>0 then begin
    if x and $FF00 <> 0 then begin x := x shr 8;  inc(r,8); end;
    if x and $00F0 <> 0 then begin x := x shr 4;  inc(r,4); end;
    if x and $000C <> 0 then begin x := x shr 2;  inc(r,2); end;
    if x and $0002 <> 0 then inc(r);
    bitsize32 := r+1;
  end
  else bitsize32 := r;
end;


{---------------------------------------------------------------------------}
function __GCD32(A, B: UInt32): UInt32;
  {-calculate GCD of unsigned (A,B)}
var
  T: UInt32;
begin
  if A=0 then __GCD32 := B
  else begin
    while B<>0 do begin
      T := B;
      B := A mod T;
      A := T;
    end;
    __GCD32 := A;
  end;
end;


{---------------------------------------------------------------------------}
function  GCD32U(A, B: longint): longint;
  {-calculate GCD of two longints (DWORD interpretation)}
begin
  GCD32U := longint(__GCD32(UInt32(A), UInt32(B)));
end;


{---------------------------------------------------------------------------}
function GCD32(A, B: longint): longint;
  {-calculate GCD of two longints}
begin
  GCD32 := longint(__GCD32(UInt32(abs(A)), UInt32(abs(B))));
end;


{---------------------------------------------------------------------------}
function invmod32(a,b: longint): longint;
  {-return a^-1 mod b, b>1. Result is 0 if gcd(a,b)<>1 or b<2}
var
  u1,u3,v1,v3,t1,t3,q: longint;
begin
  invmod32 := 0;
  if (b>1) and (a<>0) then begin
    {Use extended GCD to calculate u1*a + u2*b = u3 = gcd(a.b)  }
    {If u3 = 1, then u1 = a^-1 mod b. u2 will not be calculated.}
    {Notation from Knuth [3] Algorithm X. u3 and v3 will be >=0 }
    {and |u1| <= b, |v1| <= b, see e.g. Shoup [29], Theorem 4.3.}
    u1 := 1;
    u3 := abs(a);
    v1 := 0;
    v3 := b;
    while v3<>0 do begin
      q  := u3 div v3;
      t1 := u1 - q*v1;
      t3 := u3 - q*v3;
      u1 := v1;
      u3 := v3;
      v1 := t1;
      v3 := t3;
    end;
    if u3=1 then begin
      {gcd(a,b)=1, so inverse exists: do some sign related adjustments.}
      if u1<0 then inc(u1,b);
      if (a<0) and (u1<>0) then invmod32 := b-u1 else invmod32 := u1;
    end
  end;
end;


(*
{---------------------------------------------------------------------------}
function add32_ovr(x,y: longint; var z: longint): boolean;
  {-add z=x+y with overflow detection}
var
  OK: boolean;
  i64: int64;
begin
  i64 := int64(x) + y;
  OK := (abs(i64) < MaxLongint) or (i64=$80000000);
  add32_ovr := not OK;
  z := longint(i64 and $FFFFFFFF);
end;
*)

{---------------------------------------------------------------------------}
function add32_ovr(x,y: longint; var z: longint): boolean;
  {-add z=x+y with overflow detection}
begin
  {See Hacker's delight, Ch 2-12}
  {$ifopt Q+}
    z := longint(int64(x)+y);
  {$else}
    z := x+y;
  {$endif}
  add32_ovr := ((z xor x) and (z xor y)) < 0;
end;


{$ifdef FPC}

{---------------------------------------------------------------------------}
function IAlloc(lsize: longint): pointer;
  {-allocate heap > 64K, return nil if error, no diagnostics}
var
  p: pointer;
  sh: boolean;
begin
  sh := ReturnNilIfGrowHeapFails;
  ReturnNilIfGrowHeapFails := true;
  getmem(p, lsize);
  ReturnNilIfGrowHeapFails := sh;
  IAlloc:= p;
end;

{$else}

{---------------------------------------------------------------------------}
function IAlloc(lsize: longint): pointer;
  {-allocate heap > 64K, return nil if error, no diagnostics}
var
  p: pointer;
begin
  try
    getmem(p, lsize);
  except
    p := nil;
  end;
  IAlloc := p;
end;

{$endif FPC}

{---------------------------------------------------------------------------}
function mp_realloc(p: pointer; oldsize, newsize: longint): pointer;
  {-reallocate heap to new size, if newsize>oldsize the new allocated space is zerofilled}
var
  tmp: pointer;
begin
  if oldsize=newsize then begin
    mp_realloc := p;
    exit;
  end;
  tmp := p;
  ReallocMem(tmp, newsize);
  mp_realloc := tmp;
  if tmp<>nil then begin
    {$ifdef MPC_Diagnostic}
      inc(mp_memstat.MemDiff, newsize);
      dec(mp_memstat.MemDiff, oldsize);
    {$endif}
    if newsize>oldsize then begin
      {zero fill new part}
      inc(Ptr2Inc(tmp),oldsize);
      fillchar(tmp^,newsize-oldsize,0);
    end;
  end;
end;
