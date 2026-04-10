+++
title = 'Colophon'
+++

This site is built with [Hugo](https://gohugo.io), a static site generator
written in Go. Styling uses [Tailwind CSS](https://tailwindcss.com), provided
by Nix — no Node.js or npm in the toolchain. There is no JavaScript.

The development environment is a [Nix flake](https://nixos.wiki/wiki/Flakes)
that pins every dependency. Images are dithered with a Python script using
ordered Bayer dithering to reduce file size while keeping the low-tech
aesthetic.

The site is designed to fit within a 1MB total capacity budget. Individual
pages are budgeted at 16KB. Dates are displayed as seasons rather than exact
dates. Log entries fade as they age — slightly after one year, more after three.
After five years, entries expire from the build entirely. The content files
remain in the repository but Hugo stops rendering them.

The accent color shifts with the season: green in spring, yellow in summer,
orange in autumn, blue-green in winter.

Source code is licensed under [EUPL-1.2](https://eupl.eu/).
