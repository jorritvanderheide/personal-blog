# personal-blog

Personal blog written in Hugo. Topics: data portability, open data formats,
interoperability, and NixOS.

## Setup

Requires [Nix](https://nixos.org/) with flakes enabled.

```sh
nix develop        # enter dev shell (Hugo, Node, Python, mask)
mask install       # install npm dependencies
```

## Development

```sh
mask serve         # start Hugo dev server
mask dither        # generate dithered images
```

## Build

```sh
hugo --gc --minify
```

## License

[EUPL-1.2](LICENSE)
