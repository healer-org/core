require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task :set_up_configs do
  %w(database).each do |file_basename|
    next if File.exist?("config/#{file_basename}.yml")
    system(`cp config/#{file_basename}.yml.example config/#{file_basename}.yml`)
  end
end

task(set_test_environment: %w(environment)) do
  ENV["RAILS_ENV"] = "test"
end

require "rubocop/rake_task"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ["--display-cop-names", "--fail-fast"]
end

task(test: %w(set_up_configs set_test_environment spec rubocop))
task(default: %w(test rubocop))
