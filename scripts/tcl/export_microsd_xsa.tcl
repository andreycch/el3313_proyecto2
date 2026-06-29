open_project Projects/el3313_proyecto2/el3313_proyecto2.xpr

set bit_path [file normalize "Projects/el3313_proyecto2/el3313_proyecto2.runs/impl_1/system_io_wrapper.bit"]
set xsa_path [file normalize "workspace/el3313_platform_microsd.xsa"]

write_hw_platform -fixed -include_bit -force -file $xsa_path

puts "XSA exportado en: $xsa_path"
close_project
