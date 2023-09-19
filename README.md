<div style="margin-right: 15px; float: left;">
  <img
    align="left"
    src="assets/logo.svg"
    alt="OpenID Connect Logo"
    width="170px"
  />
</div>

# Phx Gen Oidcc

An OpenID Login Generator for Phoenix 1.7 Projects

[![EEF Security WG project](https://img.shields.io/badge/EEF-Security-black)](https://github.com/erlef/security-wg)
[![Main Branch](https://github.com/Erlang-Openid/phx_gen_oidcc/actions/workflows/branch_main.yml/badge.svg?branch=main)](https://github.com/Erlang-Openid/phx_gen_oidcc/actions/workflows/branch_main.yml)
[![Module Version](https://img.shields.io/hexpm/v/phx_gen_oidcc.svg)](https://hex.pm/packages/phx_gen_oidcc)
[![Total Download](https://img.shields.io/hexpm/dt/phx_gen_oidcc.svg)](https://hex.pm/packages/phx_gen_oidcc)
[![License](https://img.shields.io/hexpm/l/phx_gen_oidcc.svg)](https://github.com/Erlang-Openid/phx_gen_oidcc/blob/main/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/Erlang-Openid/phx_gen_oidcc.svg)](https://github.com/Erlang-Openid/phx_gen_oidcc/commits/master)
[![Coverage Status](https://coveralls.io/repos/github/Erlang-Openid/phx_gen_oidcc/badge.svg?branch=main)](https://coveralls.io/github/Erlang-Openid/phx_gen_oidcc?branch=main)

<br clear="left"/>

<!-- TODO: Uncomment after certification -->
<!--
<picture style="margin-right: 15px; float: left;">
  <source
    media="(prefers-color-scheme: dark)"
    srcset="assets/certified-dark.svg"
    width="170px"
    align="left"
  />
  <source
    media="(prefers-color-scheme: light)"
    srcset="assets/certified-light.svg"
    width="170px"
    align="left"
  />
  <img
    src="assets/certified-light.svg"
    alt="OpenID Connect Certified Logo"
    width="170px"
    align="left"
  />
</picture>

OpenID Certified by Jonatan Männchen at the Erlang Ecosystem Foundation for the
basic and configuration profile of the OpenID Connect protocol. For details,
check the [Conformance Documentation](https://github.com/erlef/oidcc/tree/openid-foundation-certification).

<br clear="left"/>
-->

<picture style="margin-right: 15px; float: left;">
  <source
    media="(prefers-color-scheme: dark)"
    srcset="assets/erlef-logo-dark.svg"
    width="170px"
    align="left"
  />
  <source
    media="(prefers-color-scheme: light)"
    srcset="assets/erlef-logo-light.svg"
    width="170px"
    align="left"
  />
  <img
    src="assets/erlef-logo-light.svg"
    alt="Erlang Ecosystem Foundation Logo"
    width="170px"
    align="left"
  />
</picture>

The development of the library and the certification is funded as an
[Erlang Ecosystem Foundation](https://erlef.org/) stipend entered by the
[Security Working Group](https://erlef.org/wg/security).

<br clear="left"/>

This library has taken some inspiration from
[@aaronrenner](https://github.com/aaronrenner)'s
[`phx_gen_auth`](https://github.com/aaronrenner/phx_gen_auth).

## Overview

The purpose of `phx.gen.oidcc` is to generate a pre-built authentication system
into a Phoenix 1.7 application that follows both security and elixir best
practices. By generating code into the user's application instead of using a
library, the user has complete freedom to modify the authentication system so it
works best with their app.

## Installation

After running `mix phx.new`, `cd` into your application's directory
(ex. `my_app`).

1. Add `phx_gen_oidcc` to your list of dependencies in `mix.exs`
    ```elixir
    def deps do
      [
        {:phx_gen_oidcc, "~> 0.1.0", only: [:dev], runtime: false},
        ...
      ]
    end
    ```
1. Install and compile the dependencies
    ```
    $ mix do deps.get, deps.compile
    ```

## Running the generator

From the root of your phoenix app, you
can install the authentication system with the following command

```console
$ mix phx.gen.oidcc \
    MyApp.ConfigProviderName \
    "https://isser.example.com" \
    "client_id" \
    "client_secret"
```

This creates the templates,views, and controllers on the web namespace, and
starts a new `Oidcc.ProviderConfiguration.Worker`, in the application.

Next, let's install the dependencies

```console
$ mix deps.get
```

Let's run the tests and make sure our new authentication system works as
expected.

```console
$ mix test
```

Finally, let's start our phoenix server and try it out.

```console
$ mix phx.server
```

## Learning more

To learn more about `phx.gen.oidcc`, run the following command.

```console
$ mix help phx.gen.oidcc
```

You can also look up the mix task in
[hexdocs](https://hexdocs.pm/phx_gen_oidcc).
