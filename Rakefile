require File.expand_path('../config/application', __FILE__)

task :set_up_configs do
  %w(database).each do |file_basename|
    next if File.exist?("config/#{file_basename}.yml")
    system(`cp config/#{file_basename}.yml.example config/#{file_basename}.yml`)
  end
end

task(:set_test_environment) do
  ENV["RAILS_ENV"] = "test"
end

require "rubocop/rake_task"
RuboCop::RakeTask.new(:run_rubocop) do |task|
  task.options = ["--display-cop-names", "--fail-fast"]
end

task(run_tests: %w(set_test_environment spec))
task(default: %w(set_up_configs run_tests run_rubocop))

Rails.application.load_tasks
