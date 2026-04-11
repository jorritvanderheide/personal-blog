# Tasks

## serve

> Serves Hugo for development

```sh
hugo serve --noHTTPCache --disableFastRender
```

## build

> Builds the site for production

```sh
hugo --gc --minify
python3 tools/calculate_size.py --directory public/
```

## dither

> Dithers all content images

```sh
python3 tools/dither-images.py
```

## update

> Updates Nix flake dependencies

```sh
nix flake update
```
