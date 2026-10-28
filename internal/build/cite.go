package build

import (
	"fmt"
	"html"
	"html/template"
	"strings"

	"codeberg.org/BW20/personal-blog/internal/content"
	"codeberg.org/BW20/personal-blog/internal/site"
)

// citation is "Cite this post": one citation in a fixed author-date form,
// written by the site itself, as it formats nothing else.
func citation(c content.Config, p *site.Post) template.HTML {
	url := address(c, p)
	return template.HTML(fmt.Sprintf("%s, %s. %d. “%s.” <em>%s</em>, %s. <a href=\"%s\">%s</a>.",
		html.EscapeString(c.Author.Family), html.EscapeString(c.Author.Given), p.Date.Year(),
		html.EscapeString(p.Title), html.EscapeString(c.Title), p.Date.Format("2 January"),
		html.EscapeString(url), html.EscapeString(url)))
}

// bibtex is the post as a BibTeX (biblatex) entry, keyed by its slug.
func bibtex(c content.Config, p *site.Post) string {
	var b strings.Builder
	fmt.Fprintf(&b, "@online{%s,\n", p.Slug)
	field := func(name, value string) { fmt.Fprintf(&b, "  %s = {%s},\n", name, value) }
	field("author", bibEscape(c.Author.Family+", "+c.Author.Given))
	// Braces twice, so a style keeps the title's capitals as they are.
	field("title", "{"+bibEscape(p.Title)+"}")
	field("date", p.Date.Format("2006-01-02"))
	field("year", p.Date.Format("2006"))
	if p.DOI != "" {
		field("doi", bibEscape(p.DOI))
	}
	field("url", c.URL+p.Path())
	field("organization", bibEscape(c.Title))
	field("langid", "english")
	b.WriteString("}\n")
	return b.String()
}

// bibEscaper escapes the characters BibTeX gives a meaning of their own.
var bibEscaper = strings.NewReplacer(
	`\`, `\textbackslash{}`, `{`, `\{`, `}`, `\}`, `%`, `\%`, `&`, `\&`,
	`$`, `\$`, `#`, `\#`, `_`, `\_`, `~`, `\textasciitilde{}`, `^`, `\textasciicircum{}`,
)

func bibEscape(s string) string { return bibEscaper.Replace(s) }

// jsonLD is the post as schema.org's BlogPosting, for search engines.
// html/template writes it as JSON, escaped for a <script> element.
func jsonLD(c content.Config, p *site.Post) map[string]any {
	url := c.URL + p.Path()
	ld := map[string]any{
		"@context":         "https://schema.org",
		"@type":            "BlogPosting",
		"headline":         p.Title,
		"description":      p.Summary,
		"url":              url,
		"mainEntityOfPage": url,
		"datePublished":    p.Date.Format("2006-01-02T15:04:05Z07:00"),
		"inLanguage":       "en",
		"license":          "https://creativecommons.org/licenses/by/4.0/",
		"author":           author(c),
		"isPartOf":         map[string]any{"@type": "Blog", "name": c.Title, "url": c.URL + "/"},
	}
	if !p.Updated.IsZero() {
		ld["dateModified"] = p.Updated.Format("2006-01-02T15:04:05Z07:00")
	}
	if p.DOI != "" {
		ld["identifier"] = "https://doi.org/" + p.DOI
	}
	return ld
}

// author is who every post is by, as schema.org has a person: with their
// ORCID iD, when site.toml gives one.
func author(c content.Config) map[string]any {
	a := map[string]any{"@type": "Person", "name": c.Author.Name()}
	if c.Author.ORCID != "" {
		a["sameAs"] = "https://orcid.org/" + c.Author.ORCID
	}
	return a
}

// address is where a citation sends a reader: the post's DOI, once it has
// one, which keeps working if the site moves, or else its address.
func address(c content.Config, p *site.Post) string {
	if p.DOI != "" {
		return "https://doi.org/" + p.DOI
	}
	return c.URL + p.Path()
}
