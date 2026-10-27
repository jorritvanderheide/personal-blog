package render

import (
	"strings"
	"testing"
)

func TestMarkdown(t *testing.T) {
	tests := []struct {
		name, src string
		want      []string
		not       []string
	}{
		{
			name: "text",
			src:  "A *quiet* revolution.",
			want: []string{"<p>A <em>quiet</em> revolution.</p>"},
		},
		{
			name: "table",
			src:  "| a | b |\n| --- | --- |\n| 1 | 2 |",
			want: []string{"<table>", "<td>1</td>"},
		},
		{
			name: "strikethrough",
			src:  "~~gone~~",
			want: []string{"<del>gone</del>"},
		},
		{
			name: "footnote",
			src:  "A claim.[^1]\n\n[^1]: Its source.",
			want: []string{`<sup id="fnref:1">`, "Its source."},
		},
		{
			name: "raw HTML stays out",
			src:  "<script>alert(1)</script>\n\nText <b>bold</b>.",
			want: []string{"Text"},
			not:  []string{"<script>", "<b>"},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := Markdown([]byte(tt.src))
			if err != nil {
				t.Fatal(err)
			}
			for _, w := range tt.want {
				if !strings.Contains(string(got), w) {
					t.Errorf("no %q in\n%s", w, got)
				}
			}
			for _, n := range tt.not {
				if strings.Contains(string(got), n) {
					t.Errorf("%q in\n%s", n, got)
				}
			}
		})
	}
}
