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
end
