if defined?(PryByebug)
  debugging_commands = {
    c: "continue",
    f: "finish",
    n: "next",
    s: "step"
  }

  debugging_commands.each do |shortcut, command|
    Pry.commands.alias_command(shortcut, command)
  end

  repeatable_commands = %w[up down] + debugging_commands.to_a.flatten.map(&:to_s)
  Pry::Commands.command(/^$/, "repeat last command") do
    command = Pry.history.to_a.last
    pry_instance.run_command(command) if command.in?(repeatable_commands)
  end

  # Filters frames based on closeness to the current directory
  # Useful for filtering out gem internals, but allowing insight local gems
  def Pry.filter_frames(frames, level_depth = 0)
    groups = Dir.pwd[1..-1].split("/").map do |dirname|
      "(?:(#{dirname})|[^/]+)"
    end

    regex = /^(?: *\d+: )?\/#{groups.join("/")}/
    pwd_level = groups.length

    known_levels = Set.new
    frames_and_levels = []

    # Assign each frame a level based on closeness to the working directory
    # If it doesn't match at all, it gets a nil level which counts as max
    frames.each do |frame|
      matches = regex.match(frame)

      if matches
        level = pwd_level - matches.to_a.compact.length + 1
        known_levels << level
      end

      frames_and_levels << [frame.strip, level]
    end

    known_levels = known_levels.sort
    max_level = known_levels.last + 1
    max_allowed_level = known_levels[level_depth] || max_level

    # Reject pry frames and those that are further than the current directory
    # than desired, based on how many bangs there were in the command
    frames = []
    frames_and_levels.each do |(frame, level)|
      if (
        (level || max_level) <= max_allowed_level &&
        frame !~ /^\(pry\)/ &&
        frame !~ /\/pry-#{Pry::VERSION}/ &&
        frame !~ /\/pry-byebug-(\d|\.)/ &&
        frame !~ /\/byebug-(\d|\.)+\//
      )
        frames << frame
      end
    end

    frames
  end

  Pry::Commands.command(/^b([?!]*)$/, "show current frames filtered to working directory") do |captures|
    # Include frame numbers since they actually are frames
    frames = Pry::Code.new(caller, 0, :text).with_line_numbers.lines
    pry_instance.pager.page Pry.filter_frames(frames, captures.length).join($/)
  end

  # Like wtf, but filtered like the "b" command
  Pry::Commands.command(/^huh([?!]*)$/, "show last error and backtrace filtered to working directory") do |captures|
    error = pry_instance.last_exception
    raise Pry::CommandError, "No most-recent exception" unless error

    pry_instance.pager.page "#{Pry::Helpers::Text.bold("Exception:")} #{error.class}: #{error.message}"
    pry_instance.pager.page "--"

    # Exclude frame numbers since it is just confusing with pry lines filtered out
    pry_instance.pager.page Pry.filter_frames(error.backtrace, captures.length).join($/)
  end
end

if defined?(ActiveRecord::Base)
  Pry::Commands.block_command "toggle-active-record-logging", "Toggle ActiveRecord logging" do
    if ActiveRecord::Base.logger.level == Logger::INFO
      ActiveRecord::Base.logger.level = Logger::DEBUG
      output.puts "ActiveRecord logging enabled"
    else
      ActiveRecord::Base.logger.level = Logger::INFO
      output.puts "ActiveRecord logging disabled"
    end
  end
end

if defined?(Rails) && Rails::VERSION::MAJOR == 4
  Pry::Commands.block_command "tee-active-record-logging", "Tee ActiveRecord logger to STDOUT" do
    Rails.logger.extend(ActiveSupport::Logger.broadcast(Logger.new(STDOUT)))
  end
end
