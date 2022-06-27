# No touch, griefer!
Per-IP interact privilege bans. When you don't want to permanently ban griefers but rather rip their arms off, and have it be enforced for all potentially new accounts under that IP.

Use `/interactban` to ban an IP, if the player is online you can specify their username and their IP will be interact-banned right away. To unban an IP, use `/interactunban` (does not work with players (yet)).

To bulk-ban a list of IP addresses, put a list of them in `interactban.txt` at the world path and use `/ib_bulk` to process it.

## TODO
- Ability to export IP list
- IPv6 support
- Also unbanning online players with /interactunban?
