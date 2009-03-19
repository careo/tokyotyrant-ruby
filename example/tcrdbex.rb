require 'tokyotyrant'
include TokyoTyrant

# create the object
rdb = RDB::new

# connect to the server
if !rdb.open("localhost", 1978)
  ecode = rdb.ecode
  STDERR.printf("open error: %s\n", rdb.errmsg(ecode))
end

# store records
if !rdb.put("foo", "hop") ||
    !rdb.put("bar", "step") ||
    !rdb.put("baz", "jump")
  ecode = rdb.ecode
  STDERR.printf("put error: %s\n", rdb.errmsg(ecode))
end

# retrieve records
value = rdb.get("foo")
if value
    printf("%s\n", value)
else
  ecode = rdb.ecode
  STDERR.printf("get error: %s\n", rdb.errmsg(ecode))
end

# traverse records
rdb.iterinit
while key = rdb.iternext
  value = rdb.get(key)
  if value
    printf("%s:%s\n", key, value)
  end
end

# hash-like usage
rdb["quux"] = "touchdown"
printf("%s\n", rdb["quux"])
rdb.each do |key, value|
  printf("%s:%s\n", key, value)
end

# close the connection
if !rdb.close
  ecode = rdb.ecode
  STDERR.printf("close error: %s\n", rdb.errmsg(ecode))
end
