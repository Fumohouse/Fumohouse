# Introduction

Fumohouse is a *game framework* that provides fumos as character models. This
document serves to define and iterate on Fumohouse's goals, implementation
details, and policies.

## Prior art

- [Become Fumo](https://www.roblox.com/games/6238705697/Become-Fumo) and
  [Scuffed Become
  Fumo](https://www.roblox.com/games/7363647365/Scuffed-Become-Fumo): The fumo
  games that inspired Fumohouse
- [Fumofas](https://github.com/Fumohouse/Fumofas): The predecessor to Fumohouse,
  which added [Walfas](https://walfas.org/)-like character customization for the
  Become Fumo characters
- [Roblox](https://www.roblox.com/) and [VRChat](https://hello.vrchat.com/):
  Game frameworks/platforms that resemble Fumohouse
- [Early iterations of Fumohouse and its web
  infrastructure](https://codeberg.org/ksk/)

## Goals

1. Provide libraries and infrastructure (e.g., character controller, models,
   netcode, chat, authentication, hosting) for game developers who don't want to
   start from scratch.
1. Maximize the ability for players to express themselves (e.g., by character
   customization or custom models).
1. Maximize the ability for developers to express themselves (e.g., by imposing
   minimal restrictions).
1. Foster a community of game developers/players.

## Components

Fumohouse is organized into the following components:

- [Fumohouse Core](core/index.md): The main user interface and various modules
  and tools that are used to build games for Fumohouse.
- [Fumohouse games ("Fumofa's")](fumofas/index.md): The games that utilize the
  core components.
- Business logic: Server components that manage game servers, player sessions,
  moderation, chat, etc.
