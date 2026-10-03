# frozen_string_literal: true

require "shellwords"
require "yaml"

root = File.expand_path("..", __dir__)
errors = []

settings_path = File.join(root, "config", "settings.yml")
begin
  settings = YAML.load_file(settings_path) || {}
  errors << "config/settings.yml must be a mapping" unless settings.is_a?(Hash)
  errors << "vip_sepay_enabled is missing" unless settings.key?("vip_sepay_enabled")
rescue StandardError => e
  errors << "invalid settings.yml: #{e.class}: #{e.message}"
end

Dir[File.join(root, "app", "**", "*.rb"), File.join(root, "lib", "**", "*.rb"), File.join(root, "db", "migrate", "*.rb")].each do |file|
  output = `ruby -c #{Shellwords.escape(file)} 2>&1`
  errors << "Ruby syntax error: #{file}: #{output.strip}" unless $?.success?
end

index_names = []
Dir[File.join(root, "db", "migrate", "*.rb")].each do |file|
  File.read(file).scan(/name:\s*["']([^"']+)["']/) { |m| index_names << [file, m.first] }
end
index_names.each do |file, name|
  errors << "PostgreSQL index name > 63 chars: #{name} (#{name.length}) in #{file}" if name.length > 63
end

if errors.empty?
  puts "VIP SePay plugin validation: PASS"
  exit 0
end

warn errors.join("\n")
exit 1
