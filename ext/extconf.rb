require 'mkmf'

SCRIPT_DIR = File.dirname(File.absolute_path(__FILE__))
GLPK_DIR = "#{SCRIPT_DIR}/glpk"
dir_config('glpk')

find_library("glpk", nil, "#{GLPK_DIR}/lib")
find_header("glpk.h", "#{GLPK_DIR}/include")

unless have_library("glpk")
  $stderr.puts "\nERROR: Cannot find the GLPK library, aborting."
  exit 1
end
unless have_header("glpk.h")
  $stderr.puts "\nERROR: Cannot find the GLPK header, aborting."
  exit 1
end
  
create_makefile('glpk_wrapper')
