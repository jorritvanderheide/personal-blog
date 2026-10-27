+++
title = 'Colophon'
+++

This site is built by a small program written in Go, from a folder of
Markdown files, and served as static files. There is no JavaScript.

The development environment is a [Nix flake](https://nixos.wiki/wiki/Flakes)
that pins every dependency. Images are dithered when the site is built, with
ordered Bayer dithering, to keep them small and keep the low-tech aesthetic.

## Time

Dates are displayed as seasons rather than exact dates. Log entries fade as
they age: slightly after one year, more after three. They don't expire: a
post may be cited, and a citation has to keep working.

The build number at the foot of every page counts the commits the site is
built from.

## License

Source code is licensed under [EUPL-1.2](https://eupl.eu/). Posts are
licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
