begin
  require 'highline/import'
rescue LoadError
  `gem install highline`
end

require 'highline/import'
def review
  confirm = ask("\nEverything looks good so far, Continue [Y/N] ") { |yn| yn.limit = 1, yn.validate = /[yn]/i }
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

review()

puts "\n\n#{gemname} gem has #{tags.count} tags: #{tags.join(', ')}"
tags.each do |tag|
  puts "\n\n\n BUILD FOR #{tag} ..."
  puts `git checkout tags/#{tag}`
  puts "Building for tag: #{tag}"
  puts `gem build #{gemname}.gemspec -q`
end

packages = `ls *.gem`.split(' ')
puts "\nFollowing packages were built: #{packages.join(', ')}"
review()

packages.each do |pkg|
  puts "\n\n\nPUBLISHING #{pkg} ..."
  `gem push --key github --host https://rubygems.pkg.github.com/bamboohealth #{pkg}`
end
