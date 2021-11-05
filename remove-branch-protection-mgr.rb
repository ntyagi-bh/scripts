token = ARGV[0]
repo = ARGV[1]
iteration = ARGV[2].to_i

puts "removing branch protections for repo: #{repo}, iteration: #{iteration}"

# get shell script from https://github.com/bamboohealth/github-support/blob/master/remove-branch-protection.sh
iteration.times do
 puts `bash remove-branch-protection.sh #{token} #{repo}`
end 

