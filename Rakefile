require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new { |t| t.libs << 'test' }

desc "Run tests"
task default: :test

desc "Open and IRB Console with the gem"
task :console do
  sh "bundle exec irb  -Ilib -I . -r mail/tools"
end
