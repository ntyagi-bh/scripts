begin
  require 'highline/import'
rescue LoadError
  `gem install highline`
  puts "installed dependency gem highline. please re-run the script"
  exit()
end

require 'highline/import'
def review(msg=nil)
  msg ||= "Everything looks good so far?"
  confirm = ask("\n #{msg} [Y/N] ") { |yn| yn.limit = 1, yn.validate = /[yn]/i }
  exit unless confirm.downcase == 'y'
end

main_branch = ARGV[0] || 'master'
gemname =  `pwd`.split('/').last.tr("\n", "\t").strip.split("_gem").first
tags = `git tag`.split(' ')

puts "\npulling latest from #{main_branch}"
puts `git co #{main_branch}`
puts `git pull`
puts `git fetch --all --tags`
puts "\nrepo is pointing to:"
puts `git remote -v`

puts "\n\n#{gemname} gem has #{tags.count} tags: #{tags.join(', ')}"
review()

tags.each do |tag|
  puts "\n\n\nBUILDING FOR TAG #{tag} ..."
  puts `git checkout tags/#{tag}`
  puts "Building for tag: #{tag}"
  puts `gem build #{gemname}.gemspec -q`
end

packages = `ls *.gem`.split(' ')
puts "\nFollowing packages were built: #{packages.join(', ')}"
puts("\n\n!!! Disclaimer: If tagged code gemspec metadata.allowed_push_host exist and is not pointing to GPR, gem will not publish !!!\n\n")
review('Ready to publish?')

packages.each do |pkg|
  `git co master`
  puts "\n\n\nPUBLISHING #{pkg} ..."
  `gem push --key github --host https://rubygems.pkg.github.com/bamboohealth #{pkg}`
end
