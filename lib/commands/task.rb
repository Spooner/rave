require 'rake'
require 'rake/tasklib'
require 'fileutils'
require 'yaml'
require 'warbler'

module Rave
  class Task < Warbler::Task    
    def initialize
      warbler_config = Warbler::Config.new do |config|
        gems = YAML.load(File.open(File.join(File.dirname(__FILE__), '..', 'gems.yaml'))).keys
        config.gems = gems + ['rave'] - ['warbler']
        config.includes = %w( robot.rb config.yaml )
      end
      super(:rave, warbler_config)
      define_post_war_processes
      define_deploy_task
    end
    
  private
    
    def define_post_war_processes
      namespace :rave do
        desc "Post-War cleanup"
        task :create_war  => 'rave' do
          #TODO: This needs to only run through this if the files have changed
          #Get config info
          config = YAML::load(File.open(File.join(".", "config.yaml")))
          web_inf = File.join(".", "tmp", "war", "WEB-INF")
          rave_jars = File.join(File.dirname(__FILE__), "..", "jars")
          #Delete the complete JRuby jar that warbler sticks in lib
          delete_jruby_from_lib(File.join(web_inf, "lib"))
          #Delete the complete JRuby jar from warbler itself 
          delete_jruby_from_warbler(File.join(web_inf, "gems", "gems"))
          #Copy the broken up JRuby jar into warbler #TODO Is warbler necessary? Can we just delete warbler?
          copy_jruby_chunks_to_warbler(rave_jars, Dir[File.join(web_inf, "gems", "gems", "warbler-*", "lib")].first)
          #Fix the broken paths in json-jruby
          fix_json_jruby_paths(File.join(web_inf, "gems", "gems"))
          #Add the appengine-web.xml file
          robot_name = config['robot']['id'].gsub(/@.+/, '')
          version = config['appcfg'] && config['appcfg']['version'] ? config['appcfg']['version'] : 1
          create_appengine_web(File.join(web_inf, "appengine-web.xml"), robot_name, version)
        end
      end
    end
    
    def define_deploy_task
      namespace :rave do
        desc "Deploy to Appengine"
        task :appcfg_update => :create_war do
          staging_folder = File.join(".", "tmp", "war")
          sdk_path = find_sdk
          if sdk_path
            appcfg_jar = File.join(sdk_path, 'lib', 'appengine-tools-api.jar')          
            require appcfg_jar
            Java::ComGoogleAppengineToolsAdmin::AppCfg.main(["update", staging_folder].to_java(:string))
          else
            puts "Unable to find the Google Appengine Java SDK"
            puts "You can either"
            puts "1. Define the path to the main SDK folder in config.yaml - e.g.:"
            puts "appcfg:"
            puts "  sdk: /usr/local/appengine-java-sdk/"
            puts "2. Add the SDK bin folder to your PATH, or"
            puts "3. Create an environment variable APPENGINE_JAVA_SDK that defines the path to the main SDK folder"
          end
        end
      end
    end
    
    def delete_jruby_from_lib(web_inf_lib)
      jar = Dir[File.join(web_inf_lib, "jruby-complete-*.jar")].first
      puts "Deleting #{jar}"
      File.delete(jar) if jar
    end

    def delete_jruby_from_warbler(web_inf_gems)
      jar = Dir[File.join(web_inf_gems, "warbler-*", "lib", "jruby-complete-*.jar")].first
      puts "Deleting #{jar}"
      File.delete(jar) if jar
    end

    def copy_jruby_chunks_to_warbler(rave_jar_dir, warbler_jar_dir)
      puts "Copying jruby chunks"
      %w( jruby-core.jar ruby-stdlib.jar ).each do |jar|
        File.copy(File.join(rave_jar_dir, jar), File.join(warbler_jar_dir, jar))
      end
    end

    def fix_json_jruby_paths(web_inf_gems)
      #TODO: Why is this necessary? Is this an appengine issue?
      puts "Fixing paths in json-jruby"
      ext = Dir[File.join(web_inf_gems, "json-jruby-*", "lib", "json", "ext.rb")].first
      if ext
        text = File.open(ext, "r") { |f| f.read }
        text.gsub!("require 'json/ext/parser'", "require 'ext/parser'")
        text.gsub!("require 'json/ext/generator'", "require 'ext/generator'")
        File.open(ext, "w") { |f| f.write(text) }
      end
    end

    def create_appengine_web(path, robot_name, version)
      puts "Creating appengine config file #{File.expand_path(path)}"
      File.open(path, "w") do |f|
        f.puts appengine_web_contents(robot_name, version)
      end
    end

    def appengine_web_contents(robot_name, version)
      <<-APPENGINE
<?xml version="1.0" encoding="utf-8"?>
<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">
    <application>#{robot_name}</application>
    <version>#{version}</version>
    <static-files />
    <resource-files />
    <sessions-enabled>false</sessions-enabled>
    <system-properties>
      <property name="jruby.management.enabled" value="false" />
      <property name="os.arch" value="" />
      <property name="jruby.compile.mode" value="JIT"/> <!-- JIT|FORCE|OFF -->
      <property name="jruby.compile.fastest" value="true"/>
      <property name="jruby.compile.frameless" value="true"/>
      <property name="jruby.compile.positionless" value="true"/>
      <property name="jruby.compile.threadless" value="false"/>
      <property name="jruby.compile.fastops" value="false"/>
      <property name="jruby.compile.fastcase" value="false"/>
      <property name="jruby.compile.chainsize" value="500"/>
      <property name="jruby.compile.lazyHandles" value="false"/>
      <property name="jruby.compile.peephole" value="true"/>
   </system-properties>
</appengine-web-app>
APPENGINE
    end
    
    def find_sdk
      unless @sdk_path
        config = YAML::load(File.open(File.join(".", "config.yaml")))
        @sdk_path = config['appcfg']['sdk'] if config['appcfg'] && config['appcfg']['sdk'] # Points at main SDK dir.
        @sdk_path ||= ENV['APPENGINE_JAVA_SDK'] # Points at main SDK dir.
        unless @sdk_path
          # Check everything in the PATH, which would point at the bin directory in the SDK.
          ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
            if File.exists?(File.join(path, "appcfg.sh")) or File.exists?(File.join("appcfg.cmd"))
              @sdk_path = File.dirname(path)
              break
            end
          end
        end
      end
      @sdk_path
    end
    
  end
end