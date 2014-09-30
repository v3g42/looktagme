namespace :tagger do
  JS_FILES  = ["external.js"]

  IMAGES = ["tag.png", "share.png", "trash.png", "ptr.png", ""]
  dest = "#{Rails.root}/chrome_extension/"
  task :prepare => :environment do
    Rake::Task['tagger:js'].execute
  end

  task :js => :environment do
    JS_FILES.each do |file|
      include_path = "includes/#{file}"
      File.write(dest + file, Uglifier.compile(Rails.application.assets.find_asset(include_path).to_s))
    end
  end

  task :images => :environment do
    JS_FILES.each do |file|
      include_path = "includes/#{file}"
      File.write(dest + file, Uglifier.compile(Rails.application.assets.find_asset(include_path).to_s))
    end
  end
end