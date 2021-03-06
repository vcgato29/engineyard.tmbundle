require "erb"
require "ostruct"

module EyCommandHelper
  # Due to need for escape gem, which name clashes with Textmate Support libs,
  # Moving the Text
  def fix_load_paths
    tm_support = $:.select { |path| path =~ %r{SharedSupport/Support/lib} }.first
    $:.reject! { |path| path =~ %r{SharedSupport/Support/lib} }
    $: << tm_support if tm_support
  end
  
  # Render output header
  def render_header
    view     = File.dirname(__FILE__) + "/../views/results_prefix.html.erb"
    template = File.read(view)
    vars     = OpenStruct.new :framework_env => environment
    print ERB.new(template).result(vars.send(:binding))
    $stdout.flush
  end
  
  def setup_ok?
    require "fileutils"
    begin
      require "rubygems"
      require "engineyard/cli"
    rescue LoadError => e
      puts <<-HTML
      </pre>
      <div class="message">
        <div class="error">Please install engineyard gem</div>
        <pre>gem install engineyard</pre>
      </div>
      HTML
      exit
    end

    unless ENV['TM_PROJECT_DIRECTORY'] && File.exist?(ENV['TM_PROJECT_DIRECTORY'])
      puts <<-HTML
      </pre>
      <div class="message">
        <div class="error">Run only from a project</div>
        <p>The Engine Yard commands are for git-based, rack/rails projects</p>
      </div>
      HTML
      exit
    end  
  end
  
  # Use git config to determine current target environment
  def environment
    "production"
  end
  
  # Do the work from engineyard gem; standard out goes straight to command output
  def run_command(command)
    ENV['THOR_SHELL'] = 'HTML'
    FileUtils.cd ENV['TM_PROJECT_DIRECTORY'] do
      begin
        EY::CLI.start([command])
      rescue EY::Error => e
        EY.ui.print_exception(e)
        exit(1)
      rescue Interrupt => e
        puts
        EY.ui.print_exception(e)
        EY.ui.say("Quitting...")
        exit(1)
      end
    end
  end
end
