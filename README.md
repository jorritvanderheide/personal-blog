# personal-blog

A static personal blog about digitalization and society, open source
infrastructure, low-tech practices, and sustainability. Built with Hugo,
styled with Tailwind via Nix. No Node.js, no npm.

## Setup

Requires [Nix](https://nixos.org/) with flakes enabled.

```sh
nix develop        # enter dev shell (Hugo, Tailwind, Python, mask)
mask serve         # start Hugo dev server
```

## Build

```sh
hugo --gc --minify
```

## Other tasks

```sh
mask dither        # generate dithered images from content
mask update        # update Nix flake dependencies
```

## License

[EUPL-1.2](LICENSE)
