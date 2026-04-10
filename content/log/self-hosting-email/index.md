+++
title = 'I stopped self-hosting email and that is fine'
summary = 'Not everything needs to be self-hosted. Knowing where to draw the line matters.'
date = 2025-09-12T16:00:00Z
expiryDate = 2030-09-12T16:00:00Z
lastmod = 2025-09-12T16:00:00Z
draft = false
cover = ''
threads = ['tech']
+++

For three years I ran my own mail server. Postfix, Dovecot, rspamd, the whole stack. It worked. It also consumed an unreasonable amount of my attention.

<!--more-->

### What I learned

Running a mail server teaches you how email actually works — SPF, DKIM, DMARC, reverse DNS, reputation scoring. Most people never see this machinery. Understanding it is valuable.

But maintaining it is a different thing. Every few months, a major provider would silently start rejecting my mail. Not bouncing — just dropping it. Debugging deliverability against opaque corporate systems is exhausting.

### Where to draw the line

Self-hosting is a spectrum, not a binary. I self-host my website, my notes, my files, my DNS. I do not self-host email anymore. The cost-benefit calculation is different for each service.

The question is not "can I run this myself" but "does running this myself give me meaningful control that I would otherwise lose." For a static website, yes. For email in a world where three companies control deliverability, the control is illusory.

### The general principle

Self-host the things where self-hosting gives you real independence. Use trusted providers for the things where the infrastructure is hostile to small operators. Purity is less useful than pragmatism.
