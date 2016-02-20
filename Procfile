file_fetcher: bundle exec sidekiq -q bump-repos_to_fetch_files_for -r ./app/init_sidekiq.rb -c 1
file_parser: bundle exec sidekiq -q bump-dependency_files_to_parse -r ./app/init_sidekiq.rb -c 1
update_checker: bundle exec sidekiq -q bump-dependencies_to_check -r ./app/init_sidekiq.rb -c 1
file_updater: bundle exec sidekiq -q bump-dependencies_to_update -r ./app/init_sidekiq.rb -c 1
pull_request_creator: bundle exec sidekiq -q bump-updated_dependency_files -r ./app/init_sidekiq.rb -c 1
