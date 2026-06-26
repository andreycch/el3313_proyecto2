setws /home/leandro/el3313_proyecto2/workspace

set platform_name el3313_platform_microsd
set xsa_path /home/leandro/el3313_proyecto2/workspace/el3313_platform_microsd.xsa
set out_dir /home/leandro/el3313_proyecto2/workspace

if {[file exists "$out_dir/$platform_name"]} {
    set backup "$out_dir/${platform_name}_bak_[clock format [clock seconds] -format %Y%m%d_%H%M%S]"
    puts "Moviendo plataforma anterior a $backup"
    file rename -force "$out_dir/$platform_name" $backup
}

puts "Creando plataforma $platform_name desde $xsa_path"

platform create \
    -name $platform_name \
    -hw $xsa_path \
    -proc microblaze_riscv_0 \
    -os standalone \
    -out $out_dir

platform active $platform_name

catch {
    domain create \
        -name standalone_microblaze_riscv_0 \
        -os standalone \
        -proc microblaze_riscv_0
}

catch {
    domain active standalone_microblaze_riscv_0
}

platform generate

puts "Plataforma microSD generada correctamente"
exit
