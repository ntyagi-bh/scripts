puts "\nrun this script from local gem repo as:"
puts "\n ruby publish_rubygems_to_gpr.rb"
puts "\t ruby publish_rubygems_to_gpr.rb <github reponame, if different than local> <main_branch, if not master>\n\n"
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

gemname =  ARGV[0] || `pwd`.split('/').last.tr("\n", "\t").strip
main_branch = ARGV[1] || 'master'

gemspec_name = Dir.glob(File.join('*.gemspec')).first
tags = `git tag`.split(' ')

puts "\npulling latest from #{main_branch}"
`git co #{main_branch} -q`
`git pull -q`
`git fetch --all --tags`
puts "\nrepo is pointing to:"
puts `git remote -v`

puts "\n\n#{gemname} gem has #{tags.count} tags: #{tags.join(', ')}"
review()

tags.each do |tag|
  puts "\n\n\nBUILDING FOR TAG #{tag} ..."
  `git checkout tags/#{tag}`

  puts "temporarily removing allowd_push_host, homepage_uri, source_code_uri, changelog_uri..."
  `sed -i '' '/allowed_push_host/d' #{gemspec_name}`
  `sed -i '' '/homepage/d' #{gemspec_name}`
  `sed -i '' '/homepage_uri/d' #{gemspec_name}`
  `sed -i '' '/source_code_uri/d' #{gemspec_name}`
  `sed -i '' '/changelog_uri/d' #{gemspec_name}`

  puts "temporarily changing github_repo..."
  `sed -i '' '/github_repo/d' #{gemspec_name}`
  baseline = `grep -n 'Gem::Specification.new' #{gemspec_name}`
  add_to_line = baseline.split(':').first.to_i + 1
  gemspec_var = baseline.split('|')[1]
  `sed -i '' '#{add_to_line}s/$/\\r\\n#{gemspec_var}.metadata["github_repo"]="ssh:\\/\\/github.com\\/bamboohealth\\/#{gemname}"/' #{gemspec_name}`

  # If your gemspec is not following conventions like not putting all code under lib/<gemname> or not including lib files in gemspec
  # puts "updating gemspec to ensure all lib files are included.."
  # `sed -i '' '/#{gemspec_var}.files/d' #{gemspec_name}`
  # `sed -i '' '#{add_to_line+1}s/$/\\r\\n#{gemspec_var}.files=Dir[\"lib\\/\\*\\*\\/\\*\"]/' #{gemspec_name}`
  #s.files        += Dir['lib/**/*.rb']

  # If gem name does not match the repo name, GPR push will fail with 404: "The expected resource was not found."
  #
  # Fix A: update your repo name to match the gemname in gemspec and re-run this from udpated repo
  #
  # Fix B(not recommended): update consumer apps to reference the gem same as repo name, in which case uncoment below lines and re-run
  # puts "temporarily updating gem name to match github_repo..."
  # `sed -i '' '/#{gemspec_var}\.name/d' #{gemspec_name}`
  # `sed -i '' '6s/$/\\r\\n#{gemspec_var}.name="#{gemname}"/' #{gemspec_name}`

  # to print gemspec used to build the gem, uncomment
  puts `cat #{gemspec_name}`

  puts "Building for tag: #{tag}"
  `gem build #{gemspec_name} -q`
  `git co .`
end
`git co master`

packages = `ls *.gem`.split(' ')
puts "\nFollowing packages were built: #{packages.join(', ')}"
puts "\mmake sure *.gem is not listed in .gitignore\n\n" if packages.empty?

review('Ready to publish?')

packages.each do |pkg|
  puts "\n\n\nPUBLISHING #{pkg} ..."
  #puts `gem push --key github --host https://rubygems.pkg.github.com/bamboohealth #{pkg}`
  ## to delete the gems got repo and packages (right hand side) > Packages Settings > Delete
  ## deleting via console is not allowed
  ## gem yank --key github --host https://rubygems.pkg.github.com/bamboohealth <gemname> -v <version>
end

built_gemname = gemspec_name.split('.gemspec').first
tags.each do |tag|
  next if packages.include?("#{built_gemname}-#{tag[1..-1]}.gem")

  puts "\n!!! ALERT: #{tag} was not built and published."
  puts "\t'git checkout tags/#{tag}' and ensure that version matches the tag\n"
end

