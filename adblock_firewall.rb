#!/usr/bin/env ruby 

require 'resolv-replace'
require 'stringio' 
require 'net/http' 
require 'open-uri' 


$directory_name = 'bl/' 
$rules_path = "/etc/ufw/user.rules"  
$existing_rules = Hash.new 
$new_entry = false 


def update_rules(addresses=[])
    baseString = "### RULES ###" 
    rules = $rules_path  
    File.open(rules, "a+") do  | file| 
          file.each_line do  |line| 
              if line.include? baseString
                tmp = StringIO.new
                addresses.each do |ip_add|
                  tmp << "\n### tuple ### deny any any 0.0.0.0/0 any #{ip_add} in" 
                  tmp << "\n-A ufw-user-input -s #{ip_add} -j DROP\n"
                end
                 line << tmp.string 
                 file.write(line) 
              end 
          end
    end 
end

def call_reload() 
    cmd = "ufw reload" 
    system(cmd) 
end

def show_status() 
    cmd = "ufw status" 
    system(cmd)
end

def save_hash()
    $existing_rules.each_key do | ip | 
        File.open("#{$directory_name}.known_address.txt", "a+").write("#{ip.strip}\n") 
    end 
end

def load_hash()
    File.open("#{$directory_name}.known_address.txt", "r").each_line { |ip| $existing_rules[ip.strip] = Time.now }   
end 

def get_addresses()
   addresses = Array.new
   text_file = Dir.glob("#{$directory_name}/*").select{ |file| /block_list/.match(file) }.first  
   black_list = File.open(text_file, "r").read 
   black_list.gsub!(/\r\n?/, "\n")
   black_list.each_line do |domain|
       ip_arr = Resolv.getaddresses(domain.strip).first
       if ip_arr != nil  && !$existing_rules.has_key?(ip_arr)
           puts "got here"
           $existing_rules[ip_arr.strip] = Time.now 
            addresses << ip_arr
      end 
   end
   puts(addresses.length) 
   puts($existing_rules.length) 
   addresses  
end

def updated_copy_bl()  
    open('https://raw.githubusercontent.com/JuJu227/personal_docs/master/block_list.txt').read  
end  

def friendly_filename(filename)
    filename.gsub(/[^\w\s_-]+/, '')
            .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
            .gsub(/\s+/, '_')
end

def clean_up() 
   Dir.glob("#{$directory_name}/*").select{ |file| /block_list/.match(file) }.each{ |file| File.delete(file)}
end 

def write_bl_disk()
    Dir.mkdir($directory_name) unless File.exists?($directory_name)
    working_file =  "#{$directory_name}#{friendly_filename("block_list_#{Time.now.utc}")}.txt"
    clean_up() 
    File.open(working_file,"w+").write(updated_copy_bl()) 
end



if __FILE__ == $0
   load_hash()
   print $existing_rules 
   write_bl_disk() 
   update_rules(get_addresses())
   save_hash() 
   call_reload()
   show_status()
end 
