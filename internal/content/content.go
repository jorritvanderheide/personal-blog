// Package content reads content/: each post's front matter and Markdown.
// It knows nothing about HTML, and reads only the fs.FS it is given, so every
// decision is tested on an in-memory site.
package content

import (
	"bytes"
	"errors"
	"fmt"
	"io/fs"
	"path"
	"slices"
	"strings"
	"time"

	"github.com/BurntSushi/toml"
)

// A Post is content/log/<slug>/index.md: its front matter, as
// docs/architecture.md describes it, and its Markdown body.
type Post struct {
	Slug string `toml:"-"`

	Title      string    `toml:"title"`
	Summary    string    `toml:"summary"`
	Date       time.Time `toml:"date"`
	Updated    time.Time `toml:"updated"`
	Threads    []string  `toml:"threads"`
	Aliases    []string  `toml:"aliases"`
	Generator  string    `toml:"generator"`
	References []string  `toml:"references"`
	Withdrawn  time.Time `toml:"withdrawn"`

	Body []byte `toml:"-"`
}

// fence opens and closes the front matter, each on a line of its own.
const fence = "+++"

// Posts reads every post under log/, sorted by slug. Each folder in log/ is
// a post, named by its slug, with its text in index.md. Every post that
// can't be read is in the error, by its file.
func Posts(fsys fs.FS) ([]Post, error) {
	entries, err := fs.ReadDir(fsys, "log")
	if err != nil {
		return nil, err
	}
	var posts []Post
	var errs []error
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		name := path.Join("log", e.Name(), "index.md")
		p, err := readPost(fsys, name)
		if err != nil {
			errs = append(errs, fmt.Errorf("%s: %w", name, err))
			continue
		}
		p.Slug = e.Name()
		posts = append(posts, p)
	}
	slices.SortFunc(posts, func(a, b Post) int { return strings.Compare(a.Slug, b.Slug) })
	return posts, errors.Join(errs...)
}

func readPost(fsys fs.FS, name string) (Post, error) {
	src, err := fs.ReadFile(fsys, name)
	if err != nil {
		return Post{}, err
	}
	front, body, err := split(src)
	if err != nil {
		return Post{}, err
	}
	var p Post
	meta, err := toml.Decode(string(front), &p)
	if err != nil {
		return Post{}, err
	}
	// A field the site doesn't know is a mistake, not something to ignore:
	// a typo would otherwise drop what it was meant to set.
	if unknown := meta.Undecoded(); len(unknown) > 0 {
		keys := make([]string, len(unknown))
		for i, k := range unknown {
			keys[i] = k.String()
		}
		return Post{}, fmt.Errorf("unknown field %s", strings.Join(keys, ", "))
	}
	var missing []string
	if p.Title == "" {
		missing = append(missing, "title")
	}
	if p.Summary == "" {
		missing = append(missing, "summary")
	}
	if p.Date.IsZero() {
		missing = append(missing, "date")
	}
	if len(missing) > 0 {
		return Post{}, fmt.Errorf("missing %s", strings.Join(missing, ", "))
	}
	p.Body = body
	return p, nil
}

// split separates the front matter, between two +++ lines at the start of
// the file, from the body after it.
func split(src []byte) (front, body []byte, err error) {
	src = bytes.ReplaceAll(src, []byte("\r\n"), []byte("\n"))
	rest, ok := bytes.CutPrefix(src, []byte(fence+"\n"))
	if !ok {
		return nil, nil, errors.New("no front matter: the file has to start with a " + fence + " line")
	}
	if front, body, ok = bytes.Cut(rest, []byte("\n"+fence+"\n")); ok {
		return front, body, nil
	}
	if front, ok = bytes.CutSuffix(rest, []byte("\n"+fence)); ok {
		return front, nil, nil
	}
	return nil, nil, errors.New("the front matter has no closing " + fence + " line")
}
