# creates a moodleversion fact, if moodle is found on the system

osfamily = Facter.value(:osfamily)

if osfamily == nil
  exit
end

case osfamily.downcase
when 'redhat'
  apachecmd = 'httpd'
when 'debian'
  apachecmd = 'apache2ctl'
end

moodle_dir = nil

results = Facter::Util::Resolution.exec("#{apachecmd} -S")
if results == nil
  exit
end

results.split("\n").each do |r|
  if r =~ /port/
    vhost_conf = r.strip.split[4].sub(/\(/,'').sub(/:\d+\)/,'')
    File.open(vhost_conf) do |f|
      f.each_line do |line|
        if line =~ /DocumentRoot.*moodle/
          moodle_dir = line.strip.split[1].tr('"','')
        end
      end
    end
  end
end

if moodle_dir then
  version = nil
  if File.exist?(moodle_dir + "/version.php")
    File.open(moodle_dir + "/version.php") do |f|
      f.each_line do |line|
        if line =~ /^\$release/
          version = line.split("'")[1]
        end
      end
    end
  end
  if version
    Facter.add(:moodleversion) do
      setcode do
        version
      end
    end
  end
end
