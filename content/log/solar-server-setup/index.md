+++
title = 'Running a website on sunlight'
summary = 'Notes on setting up a solar-powered Raspberry Pi web server.'
date = 2026-02-20T14:00:00Z
threads = ['sustainability']
+++

This site runs on a Raspberry Pi powered by a small solar panel. Here is what that actually involves.

### The hardware

A Raspberry Pi 4, a 30W solar panel, a charge controller, and a 12V battery. Total cost: around 120 euros. The Pi draws about 3-5 watts under load, which means the panel can keep it running through most of a Dutch spring day. Winter is harder.

### The constraints

The server is not always on. On cloudy winter days, uptime might be four or five hours. This is fine for a static site — visitors get the cached version from a CDN edge, and the origin only needs to be up when the site rebuilds.

But it changes how you think about publishing. You cannot deploy on demand. You deploy when the sun is out. The weather becomes part of your workflow.

### Why bother

The electricity cost is zero. The carbon footprint is negligible. The hardware will last years. And there is something satisfying about a website that depends on the weather — it makes the infrastructure visible instead of hiding it behind an abstraction.

A website does not need to be available 99.99% of the time. Most personal sites could run on sunlight and nobody would notice the difference.
