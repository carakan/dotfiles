# mosh + tmux

`mosh` gives a shell that survives walking out of Wi-Fi range: the session moves
to the new IP and keeps its state, scrollback and running processes. `tmux` gives
a session that survives *disconnecting* and lets you keep several shells side by
side. Used together, a phone can open a terminal, lose signal in a car, come
back, and land in exactly the shell it left.

How the two fit together:

- **tmux owns the work.** Panes, windows, long-running jobs survive both a mosh
  drop and a closed terminal. This box already runs the `main` session.
- **mosh owns the connection.** It re-establishes the shell without losing the
  scrollback or the foreground process, and it works over a flaky link where SSH
  would have timed out.
- Reconnecting always means attaching to the same tmux session, so the pickers
  and editors are where you left them.

## Requirements

| | status on this box |
|---|---|
| OS | Ubuntu 24.04.5 |
| sshd | active |
| mosh | **not installed** |
| router | box is at `192.168.0.4`, router WAN is `166.114.130.70` — behind NAT, so ports must be forwarded |
| firewall | `ufw` installed; rules need root |

## 1. Install mosh (needs sudo)

```sh
sudo apt update && sudo apt install -y mosh
```

This installs `mosh-server` on this box and the `mosh` client. The server needs
no configuration; it binds a free UDP port per session.

## 2. Open the ports

mosh uses one UDP port in **60000-61000** plus the SSH port (22) for the initial
handshake. Two places need to allow them:

```sh
sudo ufw allow 22/tcp                      # only if ufw is active
sudo ufw allow 60000:61000/udp
```

and on the **router**: forward

| protocol | external | internal |
|---|---|---|
| TCP | 22 | 192.168.0.4:22 |
| UDP | 60000-61000 | 192.168.0.4:60000-61000 |

Check whether the port is reachable from outside before trusting the setup:

```sh
# from the phone's cellular network, not Wi-Fi
nc -u -z 166.114.130.70 60000 && echo reachable
```

If the router's WAN address is not a real public IP (some ISPs use CGNAT in
100.64.0.0/10), inbound connections are impossible and mosh only works on the
local network or through a VPN. The address here is a normal public one, so a
forward should be enough.

## 3. Key-based login from the phone

mosh starts by running `ssh` to launch the server, so the phone needs a
non-interactive login. Copy the phone's public key here (Termius, Blink Shell
and friends can show or generate one):

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat >> ~/.ssh/authorized_keys        # paste the phone's public key, then Ctrl-D
chmod 600 ~/.ssh/authorized_keys
```

Until a key is in place, mosh falls back to a password prompt on every
reconnect — workable, but the prompt is the part that fails on a bad link, which
is the case mosh exists to solve.

## 4. Use it

Start or attach the session in one step:

```sh
mosh carakan@166.114.130.70 -- tmux new-session -A -s main
```

- `-A` attaches if `main` exists, creates it if not — no "session already
  exists" error.
- Reconnecting after roaming is the same command. The shell comes back, and the
  session is the one that was already running.

Useful tmux moves once you are in:

| key | action |
|---|---|
| `prefix` + `c` | new window (the prefix is `C-a` here) |
| `prefix` + `d` | detach, leaving everything running |
| `prefix` + `Tab` | switch pane (the fzf list, most-recently-used first) |
| `prefix` + `C-f` | fzf launcher: sessions, windows, panes, commands, processes |

## Interaction with the tmux-fzf pickers

The plugin reads the geometry of the client that pressed the key, so the same
picker adapts to the screen it opens on: a phone in landscape, or a short split
terminal, gets the near-fullscreen compact layout with no preview pane, and a
desktop window gets the preview. A phone reporting a narrow column count
(`prefix` + `C-f` from Termius) gets it too. Nothing in this document changes
that behaviour — mosh just makes the connection survive long enough to use it.

## Troubleshooting

| symptom | cause |
|---|---|
| `mosh: command not found` on the client | the phone app has no mosh client; Blink Shell and most Android terminals have one |
| connects over Wi-Fi, fails on cellular | port forwarding or `ufw` missing for 60000-61000/udp |
| `mosh-server: no matching cipher` | ancient client; update it |
| drops every ~30 s | UDP being throttled or blocked upstream; check the router's UDP handling |
| session gone after reconnecting | `tmux new-session` was used instead of `tmux new-session -A -s main` |