# WireGuard Orb


[![CircleCI Build Status](https://circleci.com/gh/orbiously/wireguard-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/orbiously/wireguard-orb) [![CircleCI Orb Version](https://badges.circleci.com/orbs/orbiously/wireguard.svg)](https://circleci.com/orbs/registry/orb/orbiously/wireguard) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/orbiously/wireguard-orb/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

This orb will allow users to connect the build-host to a remote WireGuard server and to redirect traffic to IP addresses/ranges specified in the `AllowedIPs` list of the WireGuard client’s configuration file, through the established WireGuard VPN tunnel.

_Note that traffic between the build-agent and other CircleCI components/services, as well as, DNS requests **will not** be routed through the WireGuard VPN tunnel._

**This is an “executor-agnostic” orb; there is only one set of commands which can be used on any _supported_ executor. The orb’s underlying code handles the OS/platform detection, and runs the appropriate OS-specific bash commands.**

## Executor support

| Linux (`machine`)  | Windows | macOS  | Docker |
| ------------- | ------------- | ------------- | ------------- |
| :white_check_mark:  | :white_check_mark:  | :white_check_mark:  | :x:  |

---

## Requirements

Before attempting to use the Wireguard orb , you’ll need to ensure that:

- You have access to a running WireGuard server whose configuration references at least 1 [Peer]. (You can refer to [this DigitalOcean tutorial](https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-20-04) to set up WireGuard on Ubuntu 20.04)
    
  You can generate keys/config using either:

  - the `wg` command included in WireGuard (run `wg -help` for more info).
    
  - the [_"Wireguard Config Generator”_ online tool](https://www.wireguardconfig.com/).

- The WireGuard server can be reached on its configured [ListenPort] (default: 51820) from any [IP address potentially used by CircleCI](https://circleci.com/docs/2.0/ip-ranges/#aws-and-gcp-ip-addresses). 

- The [Peer]'s (WireGuard client) configuration file has been base64-encoded and stored as an environment variable, either in the project settings or in an organization context.


## Features

This orb has 3 commands:
- `setup`
- `connect`
- `disconnect`

There are **no job or executor** defined in this orb.

### Commands

The `setup` command will:
- Download/Install WireGuard (if needed ).
- Populate the WireGuard client configuration file.

The `connect` command will:
- Add exclusions for CircleCI-specific routes.
- Connect the WireGuard client to the WireGuard server.

The `disconnect` command will:
- Disconnect the client from the WireGuard server.
- Delete the WireGuard client configuration file.


## Caveats & limitations

- The orb adds route exclusions to prevent traffic between the build-agent and other CircleCI components/services, as well as, DNS requests from being routed through the WireGuard VPN tunnel.

  This is necessary to avoid networking issues when the WireGuard client is configured to route all traffic through the WireGuard VPN tunnel.
  
  However, these routes are based on the current architecture of the CircleCI build-environement, which is subject to change over time thus rendering the aforementioned routes exclusions obsolete and ineffective.

- When configuring your WireGuard server and choosing an IP range, make sure it doesn't conflict with the build-host's existing network/routing configuration.

- The `docker` executor is not supported (due to [limitations of unprivileged LXC containers](https://circleci.com/blog/vpns-and-why-they-don-t-work/) used in CircleCI).

- Users invoking the orb in a Windows job have to be mindful of the [WireGuard built-in (Windows specific) "kill-switch" feature](https://git.zx2c4.com/wireguard-windows/about/docs/netquirk.md).

## Resources

[CircleCI Orb Registry Page](https://circleci.com/orbs/registry/orb/orbiously/wireguard) - The official registry page of this orb for all versions and commands described.

[CircleCI Orb Docs](https://circleci.com/docs/2.0/orb-intro/#section=configuration) - Docs for using, creating, and publishing CircleCI Orbs.

## Important note regarding support

This is an [**uncertified** orb](https://circleci.com/docs/orbs-faq#using-uncertified-orbs); it is **neither tested nor verified by CircleCI**. Therefore CircleCI **will not** be in a position to assist you with using this orb, or troubleshooting/resolving any issues you might encouter while using this orb.

Should you have questions or encounter an issue while using this orb, please:

1. Refer to the "[Caveats & limitations](https://github.com/orbiously/wireguard-orb/README.md#caveats--limitations)" section.
2. Check if there is a similar [existing question/issue](https://github.com/orbiously/wireguard-orb/issues). If so, you can add details about your instance of the issue.
3. Visit the [Orb category of the CircleCI Discuss community forum](https://discuss.circleci.com/c/orbs). 
4. If none of the above helps, [open your own issue](https://github.com/orbiously/wireguard-orb/issues/new/choose) with a **detailled** description.

## Contribute

You are more than welcome to contribute to this orb by adding features/improvements or fixing open issues. To do so, please create [pull requests](https://github.com/orbiously/wireguard-orb/pulls) against this repository, and make sure to provide the requested information.