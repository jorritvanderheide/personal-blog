// Package build makes the site from what package content read: every page
// rendered into memory first, and written to disk only when all of them
// are, so an error never leaves half a site behind.
package build

import (
	"bytes"
	"errors"
	"fmt"
	"html/template"
	"io/fs"
	"os"
	"path"
	"path/filepath"

	"codeberg.org/BW20/personal-blog/internal/content"
	"codeberg.org/BW20/personal-blog/internal/render"
)

// Files is the site: each file's path, relative to the site's root, and its
// contents.
type Files map[string][]byte

// A post's page: the post, and its text as HTML.
type postPage struct {
	content.Post
	Text template.HTML
}

// Site renders every page, with the templates in templates/ of assets.
func Site(posts []content.Post, assets fs.FS) (Files, error) {
	post, err := template.ParseFS(assets, "templates/base.html", "templates/post.html")
	if err != nil {
		return nil, err
	}
	files := Files{}
	var errs []error
	for _, p := range posts {
		name := path.Join("log", p.Slug, "index.html")
		text, err := render.Markdown(p.Body)
		if err != nil {
			errs = append(errs, fmt.Errorf("%s: %w", name, err))
			continue
		}
		var buf bytes.Buffer
		if err := post.ExecuteTemplate(&buf, "base", postPage{Post: p, Text: text}); err != nil {
			errs = append(errs, fmt.Errorf("%s: %w", name, err))
			continue
		}
		files[name] = buf.Bytes()
	}
	if err := errors.Join(errs...); err != nil {
		return nil, err
	}
	return files, nil
}

// Write puts the files in dir, which mustn't exist yet or must be empty: a
// site is written whole, never over another one.
func Write(dir string, files Files) error {
	entries, err := os.ReadDir(dir)
	if err != nil && !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	if len(entries) > 0 {
		return fmt.Errorf("%s isn't empty: the site is written to a new or empty folder", dir)
	}
	for name, data := range files {
		file := filepath.Join(dir, filepath.FromSlash(name))
		if err := os.MkdirAll(filepath.Dir(file), 0o755); err != nil {
			return err
		}
		if err := os.WriteFile(file, data, 0o644); err != nil {
			return err
		}
	}
	return nil
}
