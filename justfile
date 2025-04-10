list:
    just --list

build:
    tailwindcss -i themes/personal-blog-theme/assets/css/main.css -o themes/personal-blog-theme/assets/css/output.css &
    hugo --minify

serve:
    tailwindcss -i themes/personal-blog-theme/assets/css/main.css -o themes/personal-blog-theme/assets/css/output.css &
    hugo serve

watch:
    tailwindcss -i themes/personal-blog-theme/assets/css/main.css -o themes/personal-blog-theme/assets/css/output.css --watch