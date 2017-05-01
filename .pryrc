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

  Pry::Commands.command(/^$/, "repeat last command") do
    command = Pry.history.to_a.last  
    if debugging_commands.to_a.flatten.map(&:to_s).include?(command)
      _pry_.run_command(command)
    end
  end  

  Pry::Commands.command(/^b!*$/, "show backtrace filtered to working directoy") do
    groups = Dir.pwd[1..-1].split("/").map do |dirname|
      "(?:(#{dirname})|[^/]+)"
    end

    regex = /^\/#{groups.join("/")}/
    pwd_level = groups.length

    known_levels = Set.new
    frames_and_levels = []

    # Assign each frame a level based on closeness to the working directory
    # If it doesn't match at all, it gets a nil level which counts as max
    caller.each do |frame|
      matches = regex.match(frame)

      if matches
        level = pwd_level - matches.to_a.compact.length + 1
        known_levels << level
      end

      frames_and_levels << [frame, level]
    end

    known_levels = known_levels.sort
    max_level = known_levels.last + 1
    level_depth = Pry.history.to_a.last.gsub(/[^!]/, "").length
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

    _pry_.pager.page frames.join($/)
  end
end
