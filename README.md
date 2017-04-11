# vat.nvim

### Vim as Terminal

This plugin is mostly about making the `:te` command smarter.

My plan is to include a few items:
  - [ ] A scratch buffer to create commands to send to a terminal buffer
  - [ ] Tracking of the commands sent to a terminal buffer
  - [ ] Ability to add commands to be persistent across sessions.
  - [ ] Suggestions for commands to be sent to a terminal buffer
    - [ ] Ability to add custom finders / finding strategies
  - [ ] SSH helper
    - [ ] Each of the following should be able to configured locally and in your init.vim
      - [ ] Custom commands for different user / hosts combinations
      - [ ] Custom abbrevs for different user / host combinations
      - [ ] Custom maps for different user / host combinations
      
And most importantly, have all of your other vim capabilities and extensibility.

## Inspiration

I have to use an old embedded terminal emulator at work for certain parts of our projects. It doesn't have smart completion, nice history or the ability to define custom persistent functions easily. So I thought maybe I could use nvim to be really good at text editing and then just send the results to the terminal using `jobsend(term, command)`.
    
