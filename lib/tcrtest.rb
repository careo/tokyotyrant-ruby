#! /usr/bin/ruby -w

#-------------------------------------------------------------------------------------------------
# The test cases of the remote database API
#                                                       Copyright (C) 2006-2008 Mikio Hirabayashi
# This file is part of Tokyo Tyrant.
# Tokyo Tyrant is free software; you can redistribute it and/or modify it under the terms of
# the GNU Lesser General Public License as published by the Free Software Foundation; either
# version 2.1 of the License or any later version.  Tokyo Tyrant is distributed in the hope
# that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
# License for more details.
# You should have received a copy of the GNU Lesser General Public License along with Tokyo
# Tyrant; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA 02111-1307 USA.
#-------------------------------------------------------------------------------------------------


require 'tokyotyrant'
include TokyoTyrant


# main routine
def main
  ARGV.length >= 1 || usage
  if ARGV[0] == "write"
    rv = runwrite
  elsif ARGV[0] == "read"
    rv = runread
  elsif ARGV[0] == "remove"
    rv = runremove
  elsif ARGV[0] == "rcat"
    rv = runrcat
  elsif ARGV[0] == "misc"
    rv = runmisc
  elsif ARGV[0] == "table"
    rv = runtable
  else
    usage
  end
  GC.start
  return rv
end


# print the usage and exit
def usage
  STDERR.printf("%s: test cases of the remote database API\n", $progname)
  STDERR.printf("\n")
  STDERR.printf("usage:\n")
  STDERR.printf("  %s write [-port num] [-nr] [-rnd] host rnum\n", $progname)
  STDERR.printf("  %s read [-port num] [-mul num] [-rnd] host rnum\n", $progname)
  STDERR.printf("  %s remove [-port num] [-rnd] host rnum\n", $progname)
  STDERR.printf("  %s rcat [-port num] [-shl num] [-dai|-dad] [-ext name] [-xlg|-xlr]" +
                   " host rnum\n", $progname)
  STDERR.printf("  %s misc [-port num] host rnum\n", $progname)
  STDERR.printf("  %s table [-port num] host rnum\n", $progname)
  STDERR.printf("\n")
  exit(1)
end


# print error message of remote database
def eprint(rdb, func)
  ecode = rdb.ecode
  STDERR.printf("%s: %s: error: %d: %s\n", $progname, func, ecode, rdb.errmsg(ecode))
end


# parse arguments of write command
def runwrite
  host = nil
  rnum = nil
  port = 1978
  nr = false
  rnd = false
  i = 1
  while i < ARGV.length
    if !host && ARGV[i] =~ /^-/
      if ARGV[i] == "-port"
        usage if (i += 1) >= ARGV.length
        port = ARGV[i].to_i
      elsif ARGV[i] == "-nr"
        nr = true
      elsif ARGV[i] == "-rnd"
        rnd = true
      else
        usage
      end
    elsif !host
      host = ARGV[i]
    elsif !rnum
      rnum = ARGV[i].to_i
    else
      usage
    end
    i += 1
  end
  usage if !host || !rnum || rnum < 1
  rv = procwrite(host, port, rnum, nr, rnd)
  return rv
end


# parse arguments of read command
def runread
  host = nil
  port = 1978
  mul = 0
  rnd = false
  i = 1
  while i < ARGV.length
    if !host && ARGV[i] =~ /^-/
      if ARGV[i] == "-port"
        usage if (i += 1) >= ARGV.length
        port = ARGV[i].to_i
      elsif ARGV[i] == "-mul"
        usage if (i += 1) >= ARGV.length
        mul = ARGV[i].to_i
      elsif ARGV[i] == "-rnd"
        rnd = true
      else
        usage
      end
    elsif !host
      host = ARGV[i]
    else
      usage
    end
    i += 1
  end
  usage if !host
  rv = procread(host, port, mul, rnd)
  return rv
end


# parse arguments of remove command
def runremove
  host = nil
  port = 1978
  rnd = false
  i = 1
  while i < ARGV.length
    if !host && ARGV[i] =~ /^-/
      if ARGV[i] == "-port"
        usage if (i += 1) >= ARGV.length
        port = ARGV[i].to_i
      elsif ARGV[i] == "-rnd"
        rnd = true
      else
        usage
      end
    elsif !host
      host = ARGV[i]
    else
      usage
    end
    i += 1
  end
  usage if !host
  rv = procremove(host, port, rnd)
  return rv
end


# parse arguments of rcat command
def runrcat
  host = nil
  rnum = nil
  port = 1978
  shl = 0
  dai = false
  dad = false
  ext = nil
  xopts = 0
  i = 1
  while i < ARGV.length
    if !host && ARGV[i] =~ /^-/
      if ARGV[i] == "-port"
        usage if (i += 1) >= ARGV.length
        port = ARGV[i].to_i
      elsif ARGV[i] == "-shl"
        usage if (i += 1) >= ARGV.length
        shl = ARGV[i].to_i
      elsif ARGV[i] == "-dai"
        dai = true
      elsif ARGV[i] == "-dad"
        dad = true
      elsif ARGV[i] == "-ext"
        usage if (i += 1) >= ARGV.length
        ext = ARGV[i]
      elsif ARGV[i] == "-xlr"
        xopts |= RDB::XOLCKREC
      elsif ARGV[i] == "-xlg"
        xopts |= RDB::XOLCKGLB
      else
        usage
      end
    elsif !host
      host = ARGV[i]
    elsif !rnum
      rnum = ARGV[i].to_i
    else
      usage
    end
    i += 1
  end
  usage if !host || !rnum || rnum < 1
  rv = procrcat(host, port, rnum, shl, dai, dad, ext, xopts)
  return rv
end


# parse arguments of misc command
def runmisc
  host = nil
  rnum = nil
  port = 1978
  i = 1
  while i < ARGV.length
    if !host && ARGV[i] =~ /^-/
      if ARGV[i] == "-port"
        usage if (i += 1) >= ARGV.length
        port = ARGV[i].to_i
      else
        usage
      end
    elsif !host
      host = ARGV[i]
    elsif !rnum
      rnum = ARGV[i].to_i
    else
      usage
    end
    i += 1
  end
  usage if !host || !rnum || rnum < 1
  rv = procmisc(host, port, rnum)
  return rv
end


# parse arguments of table command
def runtable
  host = nil
  rnum = nil
  port = 1978
  i = 1
  while i < ARGV.length
    if !host && ARGV[i] =~ /^-/
      if ARGV[i] == "-port"
        usage if (i += 1) >= ARGV.length
        port = ARGV[i].to_i
      else
        usage
      end
    elsif !host
      host = ARGV[i]
    elsif !rnum
      rnum = ARGV[i].to_i
    else
      usage
    end
    i += 1
  end
  usage if !host || !rnum || rnum < 1
  rv = proctable(host, port, rnum)
  return rv
end


# perform write command
def procwrite(host, port, rnum, nr, rnd)
  printf("<Writing Test>\n  host=%s  port=%d  rnum=%d  nr=%s  rnd=%s\n\n",
         host, port, rnum, nr, rnd)
  err = false
  stime = Time.now
  rdb = RDB::new
  if !rdb.open(host, port)
    eprint(rdb, "open")
    err = true
  end
  if !rnd && !rdb.vanish
    eprint(rdb, "vanish")
    err = true
  end
  for i in 1..rnum
    buf = sprintf("%08d", rnd ? rand(rnum) + 1: i)
    if nr
      if !rdb.putnr(buf, buf)
        eprint(rdb, "putnr")
        err = true
        break
      end
    else
      if !rdb.put(buf, buf)
        eprint(rdb, "put")
        err = true
        break
      end
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("record number: %d\n", rdb.rnum)
  printf("size: %d\n", rdb.size)
  if !rdb.close
    eprint(rdb, "close")
    err = true
  end
  printf("time: %.3f\n", Time.now - stime)
  printf("%s\n\n", err ? "error" : "ok")
  return err ? 1 : 0
end


# perform read command
def procread(host, port, mul, rnd)
  printf("<Reading Test>\n  host=%s  port=%d  mul=%d  rnd=%s\n\n", host, port, mul, rnd)
  err = false
  stime = Time.now
  rdb = RDB::new
  if !rdb.open(host, port)
    eprint(rdb, "open")
    err = true
  end
  recs = Hash.new
  rnum = rdb.rnum
  for i in 1..rnum
    buf = sprintf("%08d", rnd ? rand(rnum) + 1: i)
    if mul > 1
      recs[buf] = ""
      if i % mul == 0
        if rdb.mget(recs) < 0
          eprint(rdb, "mget")
          err = true
          break
        end
        recs.clear
      end
    else
      if !rdb.get(buf) && !rnd
        eprint(rdb, "get")
        err = true
        break
      end
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("record number: %d\n", rdb.rnum)
  printf("size: %d\n", rdb.size)
  if !rdb.close
    eprint(rdb, "close")
    err = true
  end
  printf("time: %.3f\n", Time.now - stime)
  printf("%s\n\n", err ? "error" : "ok")
  return err ? 1 : 0
end


# perform remove command
def procremove(host, port, rnd)
  printf("<Removing Test>\n  host=%s  port=%d  rnd=%s\n\n", host, port, rnd)
  err = false
  stime = Time.now
  rdb = RDB::new
  if !rdb.open(host, port)
    eprint(rdb, "open")
    err = true
  end
  rnum = rdb.rnum
  for i in 1..rnum
    buf = sprintf("%08d", rnd ? rand(rnum) + 1: i)
    if !rdb.out(buf) && !rnd
      eprint(rdb, "out")
      err = true
      break
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("record number: %d\n", rdb.rnum)
  printf("size: %d\n", rdb.size)
  if !rdb.close
    eprint(rdb, "close")
    err = true
  end
  printf("time: %.3f\n", Time.now - stime)
  printf("%s\n\n", err ? "error" : "ok")
  return err ? 1 : 0
end


# perform rcat command
def procrcat(host, port, rnum, shl, dai, dad, ext, xopts)
  printf("<Random Concatenating Test>\n  host=%s  port=%d  rnum=%d  shl=%d  dai=%s  dad=%s" +
         "  ext=%s  xopts=%d\n\n", host, port, rnum, shl, dai, dad, ext ? ext : "", xopts)
  err = false
  stime = Time.now
  rdb = RDB::new
  if !rdb.open(host, port)
    eprint(rdb, "open")
    err = true
  end
  if !rdb.vanish
    eprint(rdb, "vanish")
    err = true
  end
  for i in 1..rnum
    buf = sprintf("%08d", rand(rnum) + 1)
    if shl > 0
      if !rdb.putshl(buf, buf, shl)
        eprint(rdb, "putshl")
        err = true
        break
      end
    elsif dai
      if !rdb.addint(buf, 1)
        eprint(rdb, "addint")
        err = true
        break
      end
    elsif dad
      if !rdb.adddouble(buf, 1.0)
        eprint(rdb, "adddouble")
        err = true
        break
      end
    elsif ext
      if !rdb.ext(ext, buf, buf, xopts) && rdb.ecode != RDB::EMISC
        eprint(rdb, "ext")
        err = true
        break
      end
    else
      if !rdb.putcat(buf, buf)
        eprint(rdb, "putcat")
        err = true
        break
      end
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("record number: %d\n", rdb.rnum)
  printf("size: %d\n", rdb.size)
  if !rdb.close
    eprint(rdb, "close")
    err = true
  end
  printf("time: %.3f\n", Time.now - stime)
  printf("%s\n\n", err ? "error" : "ok")
  return err ? 1 : 0
end


# perform misc command
def procmisc(host, port, rnum)
  printf("<Miscellaneous Test>\n  host=%s  port=%d  rnum=%d\n\n", host, port, rnum)
  err = false
  stime = Time.now
  rdb = RDB::new
  if !rdb.open(host, port)
    eprint(rdb, "open")
    err = true
  end
  if !rdb.vanish
    eprint(rdb, "vanish")
    err = true
  end
  printf("writing:\n")
  for i in 1..rnum
    buf = sprintf("%08d", i)
    if rand(10) > 0
      if !rdb.putkeep(buf, buf)
        eprint(rdb, "putkeep")
        err = true
        break
      end
    else
      if !rdb.putnr(buf, buf)
        eprint(rdb, "putnr")
        err = true
        break
      end
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("reading:\n")
  for i in 1..rnum
    kbuf = sprintf("%08d", i)
    vbuf = rdb.get(kbuf)
    if !vbuf
        eprint(rdb, "get")
        err = true
        break
    end
    if vbuf != kbuf
        eprint(rdb, "(validation)")
        err = true
        break
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  if rdb.rnum != rnum
    eprint(rdb, "rnum")
    err = true
  end
  printf("random writing:\n")
  for i in 1..rnum
    kbuf = sprintf("%08d", rand(rnum) + 1)
    vbuf = "*" * rand(32)
    if !rdb.put(kbuf, vbuf)
        eprint(rdb, "put")
        err = true
        break
    end
    rbuf = rdb.get(kbuf)
    if !rbuf
        eprint(rdb, "get")
        err = true
        break
    end
    if rbuf != vbuf
        eprint(rdb, "(validation)")
        err = true
        break
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("random erasing:\n")
  for i in 1..rnum
    kbuf = sprintf("%08d", rand(rnum) + 1)
    if !rdb.out(kbuf) && rdb.ecode != RDB::ENOREC
      eprint(rdb, "out")
      err = true
      break
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("script extension calling:\n")
  for i in 1..rnum
    buf = sprintf("(%d)", rand(rnum) + 1)
    name = "put"
    case rand(7)
    when 1
      name = "putkeep"
    when 2
      name = "putcat"
    when 3
      name = "out"
    when 4
      name = "get"
    when 5
      name = "iterinit"
    when 6
      name = "iternext"
    end
    xbuf = rdb.ext(name, buf, buf)
    if !xbuf && rdb.ecode != RDB::EMISC
      eprint(rdb, "ext")
      err = true
      break
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("checking iterator:\n")
  if !rdb.iterinit
    eprint(rdb, "iterinit")
    err = true
  end
  inum = 0
  while key = rdb.iternext
    inum += 1
    value = rdb.get(key)
    if !value
      eprint(rdb, "get")
      err = true
      break
    end
    if rnum > 250 && inum % (rnum / 250) == 0
      print('.')
      if inum == rnum || inum % (rnum / 10) == 0
        printf(" (%08d)\n", inum)
      end
    end
  end
  printf(" (%08d)\n", inum) if rnum > 250
  if rdb.ecode != RDB::ENOREC || inum != rdb.rnum
    eprint(rdb, "(validation)")
    err = true
  end
  keys = rdb.fwmkeys("0", 10)
  if rdb.rnum >= 10 && keys.size != 10
    eprint(rdb, "fwmkeys")
    err = true
  end
  printf("checking counting:\n")
  for i in 1..rnum
    buf = sprintf("[%d]", rand(rnum) + 1)
    if rand(2) == 0
      if !rdb.addint(buf, 123) && rdb.ecode != RDB::EKEEP
        eprint(rdb, "addint")
        err = true
        break
      end
    else
      if !rdb.adddouble(buf, 123.456) && rdb.ecode != RDB::EKEEP
        eprint(rdb, "addint")
        err = true
        break
      end
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("checking versatile functions:\n")
  args = []
  for i in 1..rnum
    if rand(10) == 0
      name = "putlist"
      case rand(3)
      when 1
        name = "outlist"
      when 2
        name = "getlist"
      end
      if !rdb.misc(name, args)
        eprint(rdb, "misc")
        err = true
        break
      end
      args = []
    else
      buf = sprintf("(%d)", rand(rnum))
      args.push(buf)
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  if !rdb.stat
    eprint(rdb, "stat")
    err = true
  end
  if !rdb.sync
    eprint(rdb, "sync")
    err = true
  end
  if !rdb.vanish
    eprint(rdb, "vanish")
    err = true
  end
  printf("checking hash-like updating:\n")
  for i in 1..rnum
    buf = sprintf("[%d]", rand(rnum))
    case rand(4)
    when 0
      rdb[buf] = buf
    when 1
      value = rdb[buf]
    when 2
      res = rdb.has_key?(buf)
    when 3
      rdb.delete(buf)
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("checking hash-like iterator:\n")
  inum = 0
  rdb.each do |tkey, tvalue|
    if inum > 0 && rnum > 250 && inum % (rnum / 250) == 0
      print('.')
      if inum == rnum || inum % (rnum / 10) == 0
        printf(" (%08d)\n", inum)
      end
    end
    inum += 1
  end
  printf(" (%08d)\n", inum) if rnum > 250
  rdb.clear
  printf("record number: %d\n", rdb.rnum)
  printf("size: %d\n", rdb.size)
  if !rdb.close
    eprint(rdb, "close")
    err = true
  end
  printf("time: %.3f\n", Time.now - stime)
  printf("%s\n\n", err ? "error" : "ok")
  return err ? 1 : 0
end


# perform table command
def proctable(host, port, rnum)
  printf("<Table Extension Test>\n  host=%s  port=%d  rnum=%d\n\n", host, port, rnum)
  err = false
  stime = Time.now
  rdb = RDBTBL::new
  if !rdb.open(host, port)
    eprint(rdb, "open")
    err = true
  end
  if !rdb.vanish
    eprint(rdb, "vanish")
    err = true
  end
  if !rdb.setindex("", RDBTBL::ITDECIMAL)
    eprint(rdb, "setindex")
    err = true
  end
  if !rdb.setindex("str", RDBTBL::ITLEXICAL)
    eprint(rdb, "setindex")
    err = true
  end
  if !rdb.setindex("num", RDBTBL::ITDECIMAL)
    eprint(rdb, "setindex")
    err = true
  end
  printf("writing:\n")
  for i in 1..rnum
    id = rdb.genuid
    cols = {
      "str" => id,
      "num" => rand(id) + 1,
      "type" => rand(32) + 1,
    }
    vbuf = ""
    num = rand(5)
    pt = 0
    for j in 1..num
      pt += rand(5) + 1
      vbuf += "," if vbuf.length > 0
      vbuf += pt.to_s
    end
    cols["flag"] = vbuf if vbuf.length > 0
    if !rdb.put(id, cols)
      eprint(rdb, "put")
      err = true
      break
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("reading:\n")
  for i in 1..rnum
    if !rdb.get(i)
      eprint(rdb, "get")
      err = true
      break
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  recs = { 1 => "", 2 => "", 3 => "", 4 => "" }
  if rdb.mget(recs) != 4 || recs.size != 4 || recs["1"]["str"] != "1"
    eprint(rdb, "mget")
    err = true
  end
  printf("removing:\n")
  for i in 1..rnum
    if rand(2) == 0 && !rdb.out(i)
      eprint(rdb, "out")
      err = true
      break
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("searching:\n")
  qry = RDBQRY::new(rdb)
  names = [ "", "str", "num", "type", "flag", "c1" ]
  ops = [ RDBQRY::QCSTREQ, RDBQRY::QCSTRINC, RDBQRY::QCSTRBW, RDBQRY::QCSTREW, RDBQRY::QCSTRAND,
          RDBQRY::QCSTROR, RDBQRY::QCSTROREQ, RDBQRY::QCSTRRX, RDBQRY::QCNUMEQ, RDBQRY::QCNUMGT,
          RDBQRY::QCNUMGE, RDBQRY::QCNUMLT, RDBQRY::QCNUMLE, RDBQRY::QCNUMBT, RDBQRY::QCNUMOREQ ]
  types = [ RDBQRY::QOSTRASC, RDBQRY::QOSTRDESC, RDBQRY::QONUMASC, RDBQRY::QONUMDESC ]
  for i in 1..rnum
    qry = RDBQRY::new(rdb) if rand(10) > 0
    cnum = rand(4)
    for j in 1..cnum
      name = names[rand(names.length)]
      op = ops[rand(ops.length)]
      op |= RDBQRY::QCNEGATE if rand(20) == 0
      op |= RDBQRY::QCNOIDX if rand(20) == 0
      expr = rand(i).to_s
      expr += "," + rand(i).to_s if rand(10) == 0
      expr += "," + rand(i).to_s if rand(10) == 0
      qry.addcond(name, op, expr)
    end
    if rand(3) != 0
      name = names[rand(names.length)]
      type = types[rand(types.length)]
      qry.setorder(name, type)
    end
    if rand(20) == 0
      qry.setmax(10)
      res = qry.searchget
      res.each do |cols|
        pkey = cols[""]
        str = cols["str"]
        if !pkey || !str || pkey != str
          eprint(rdb, "searchget")
          err = true
          break
        end
      end
      onum = rdb.rnum
      if !qry.searchout
          eprint(rdb, "searchout")
          err = true
        break
      end
      if rdb.rnum != onum - res.size
        eprint(rdb, "(validation)")
        err = true
        break
      end
    else
      qry.setmax(rand(i)) if rand(3) != 0
      res = qry.search
    end
    if rnum > 250 && i % (rnum / 250) == 0
      print('.')
      if i == rnum || i % (rnum / 10) == 0
        printf(" (%08d)\n", i)
      end
    end
  end
  printf("record number: %d\n", rdb.rnum)
  printf("size: %d\n", rdb.size)
  if !rdb.close
    eprint(rdb, "close")
    err = true
  end
  printf("time: %.3f\n", Time.now - stime)
  printf("%s\n\n", err ? "error" : "ok")
  return err ? 1 : 0
end


# execute main
STDOUT.sync = true
$progname = $0.dup
$progname.gsub!(/.*\//, "")
srand
exit(main)



# END OF FILE
