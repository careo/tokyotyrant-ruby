require 'rbconfig'

sitelibdir = Config::CONFIG.fetch("sitelibdir")
bindir = Config::CONFIG.fetch("bindir")

def copy(src, dest, mode)
  p dest
  open(src, "rb") do |infile|
    open(dest, "wb") do |outfile|
      while buf = infile.read(8192)
        while buf.length > 0
          wlen = outfile.write(buf)
          buf = buf[wlen, buf.length]
        end
      end
      outfile.chmod(mode)
    end
  end
end

if ARGV.length > 0 && ARGV[0] == "uninstall"
  printf("uninstalling the library from %s ... ", sitelibdir)
  File.unlink("#{sitelibdir}/tokyotyrant.rb")
  printf("ok\n")
  printf("uninstalling the test command from %s ... ", bindir)
  File.unlink("#{bindir}/tcrtest.rb")
  printf("ok\n")
else
  printf("installing the library into %s ... ", sitelibdir)
  copy("tokyotyrant.rb", "#{sitelibdir}/tokyotyrant.rb", 0644)
  printf("ok\n")
  printf("installing the test command into %s ... ", bindir)
  copy("tcrtest.rb", "#{bindir}/tcrtest.rb", 0755)
  printf("ok\n")
end

printf("done\n")
