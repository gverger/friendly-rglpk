require 'mkmf'
require 'pathname'

ROOT_DIR = File.dirname(File.absolute_path(__FILE__))
PROG_NAME = "glpk-4.44"

TARBALL_NAME = "#{PROG_NAME}.tar.gz"
GLPK_DIR = "#{ROOT_DIR}/glpk-4.44"
GLPK_INSTALL = "#{ROOT_DIR}/glpk_install"
def install_glpk
  res = system "cd #{GLPK_DIR} && ./configure --prefix=#{GLPK_INSTALL} && make && make install"
  if not res
    puts "Failed to build GLPK, aborting"
    exit 1
  end
end

#install_glpk
dir_config('glpk')
find_library("glpk", nil, "#{GLPK_INSTALL}/lib")
find_header("glpk.h", "#{GLPK_INSTALL}/include")

unless have_library("glpk")
  $stderr.puts "\nERROR: Cannot find the GLPK library, aborting."
  exit 1
end
unless have_header("glpk.h")
  $stderr.puts "\nERROR: Cannot find the GLPK header, aborting."
  exit 1
end
  
create_makefile('glpk_wrapper')
