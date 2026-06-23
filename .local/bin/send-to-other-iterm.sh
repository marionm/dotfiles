#!/bin/bash
# Write a command into an iTerm2 window that ISN'T the one this was invoked from,
# then run it. Used by the vim-rspec bindings in ~/.vimrc to run tests in a
# separate iTerm window.
#
# Terminal nvim inside iTerm sets $ITERM_SESSION_ID (format "wNtNpN:UUID"); the
# UUID matches `id of session` in iTerm's AppleScript model, so we skip the whole
# window containing it. Neovide/gvim have no iTerm parent, so the var is unset and
# the first window is used.

cmd="$1"
self="${ITERM_SESSION_ID##*:}"

/usr/bin/osascript - "${self:-none}" "$cmd" <<'OSA'
on run argv
  set selfId to item 1 of argv
  set theCmd to item 2 of argv
  tell application "iTerm2"
    set targetSession to missing value
    repeat with w in windows
      set isMine to false
      repeat with t in tabs of w
        repeat with s in sessions of t
          if (id of s) is selfId then set isMine to true
        end repeat
      end repeat
      if (not isMine) and (targetSession is missing value) then
        set targetSession to current session of w
      end if
    end repeat
    if targetSession is missing value then
      set targetSession to current session of (create window with default profile)
    end if
    tell targetSession to write text theCmd
  end tell
end run
OSA
