package content

import (
	"strings"
	"testing"
	"testing/fstest"
	"time"
)

func TestPosts(t *testing.T) {
	fsys := fstest.MapFS{
		"log/quiet/index.md": {Data: []byte(`+++
title = 'The NixOS module system is a quiet revolution'
summary = 'Why declarative configuration changes how we think about infrastructure.'
date = 2026-03-15T10:00:00Z
threads = ['tech']
+++

Most people encounter NixOS and get lost in the syntax.
`)},
		"log/another/index.md": {Data: []byte("+++\ntitle = 'A'\nsummary = 'B'\ndate = 2025-01-01T00:00:00Z\n+++\n")},
		// Not a post: only folders in log/ are.
		"log/_index.md": {Data: []byte("+++\ntitle = 'Log'\n+++\n")},
	}
	posts, err := Posts(fsys)
	if err != nil {
		t.Fatal(err)
	}
	if len(posts) != 2 || posts[0].Slug != "another" || posts[1].Slug != "quiet" {
		t.Fatalf("posts = %+v, want another and quiet, by slug", posts)
	}
	p := posts[1]
	if p.Title != "The NixOS module system is a quiet revolution" {
		t.Errorf("Title = %q", p.Title)
	}
	if want := time.Date(2026, 3, 15, 10, 0, 0, 0, time.UTC); !p.Date.Equal(want) {
		t.Errorf("Date = %v, want %v", p.Date, want)
	}
	if len(p.Threads) != 1 || p.Threads[0] != "tech" {
		t.Errorf("Threads = %v", p.Threads)
	}
	if want := "\nMost people encounter NixOS and get lost in the syntax.\n"; string(p.Body) != want {
		t.Errorf("Body = %q, want %q", p.Body, want)
	}
}

// Every post that can't be read fails, with its file and what is wrong, all
// of them at once.
func TestPostsErrors(t *testing.T) {
	tests := []struct {
		name, src, want string
	}{
		{"missing", "+++\ntitle = 'A'\n+++\nText", "log/missing/index.md: missing summary, date"},
		{"unknown", "+++\ntitle = 'A'\nsummary = 'B'\ndate = 2025-01-01T00:00:00Z\nlastmod = 2025-01-01T00:00:00Z\n+++\n", "log/unknown/index.md: unknown field lastmod"},
		{"unopened", "title = 'A'\n", "log/unopened/index.md: no front matter"},
		{"unclosed", "+++\ntitle = 'A'\n", "log/unclosed/index.md: the front matter has no closing +++ line"},
		{"invalid", "+++\ntitle = \n+++\n", "log/invalid/index.md: toml:"},
	}
	fsys := fstest.MapFS{}
	for _, tt := range tests {
		fsys["log/"+tt.name+"/index.md"] = &fstest.MapFile{Data: []byte(tt.src)}
	}
	_, err := Posts(fsys)
	if err == nil {
		t.Fatal("no error")
	}
	for _, tt := range tests {
		if !strings.Contains(err.Error(), tt.want) {
			t.Errorf("error doesn't say %q:\n%v", tt.want, err)
		}
	}
}

func TestPostsWithoutIndex(t *testing.T) {
	_, err := Posts(fstest.MapFS{"log/empty/notes.md": {}})
	if err == nil || !strings.Contains(err.Error(), "log/empty/index.md") {
		t.Fatalf("err = %v, want one about log/empty/index.md", err)
	}
}
