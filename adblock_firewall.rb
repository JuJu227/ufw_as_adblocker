#!/usr/bin/env ruby 

require 'resolv-replace'
require 'stringio' 
require 'net/http' 
require 'open-uri' 


$directory_name = 'bl/' 

def update_rules(addresses=[])
    baseString = "### RULES ###" 
    rules = "/etc/ufw/user.rules"  
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

def get_addresses()
   addresses = Array.new
   text_file = Dir.glob("#{$directory_name}/*").select{ |file| /block_list/.match(file) }.first  
   black_list = File.open(text_file, "r").read 
   black_list.gsub!(/\r\n?/, "\n") 
   black_list.each_line do |domain|
       ip_arr = Resolv.getaddresses(domain.strip)
           if ip_arr.length > 0    
               addresses << ip_arr[0] 
           end 
   end
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
   write_bl_disk() 

   update_rules(get_addresses()) 

   call_reload()
   show_status() 
end 
