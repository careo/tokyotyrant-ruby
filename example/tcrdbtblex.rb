require 'tokyotyrant'
include TokyoTyrant

# create the object
rdb = RDBTBL::new

# connect to the server
if !rdb.open("localhost", 1978)
  ecode = rdb.ecode
  STDERR.printf("open error: %s\n", rdb.errmsg(ecode))
end

# store a record
pkey = rdb.genuid
cols = { "name" => "mikio", "age" => "30", "lang" => "ja,en,c" }
if !rdb.put(pkey, cols)
  ecode = rdb.ecode
  STDERR.printf("put error: %s\n", rdb.errmsg(ecode))
end

# store another record
cols = { "name" => "falcon", "age" => "31", "lang" => "ja", "skill" => "cook,blog" }
if !rdb.put("x12345", cols)
  ecode = rdb.ecode
  STDERR.printf("put error: %s\n", rdb.errmsg(ecode))
end

# search for records
qry = RDBQRY::new(rdb)
qry.addcond("age", RDBQRY::QCNUMGE, "20")
qry.addcond("lang", RDBQRY::QCSTROR, "ja,en")
qry.setorder("name", RDBQRY::QOSTRASC)
qry.setlimit(10)
res = qry.search
res.each do |rkey|
  rcols = rdb.get(rkey)
  printf("name:%s\n", rcols["name"])
end

# close the connection
if !rdb.close
  ecode = rdb.ecode
  STDERR.printf("close error: %s\n", rdb.errmsg(ecode))
end
