+++
title = 'What if your data never left your device?'
summary = 'Local-first software and the case against cloud dependency.'
date = 2026-01-08T11:00:00Z
threads = ['tech']
+++

Every note-taking app, every task manager, every document editor — they all assume a cloud backend. Your data lives on someone else's computer. Local-first software asks: what if it did not?

## The local-first principle

Your device has the canonical copy of your data. Syncing with other devices is peer-to-peer when possible, and uses servers only as relays — not as the source of truth. If the server disappears, your data is still there. If the network disappears, the app still works.

## Why this is hard

Conflict resolution. If you edit a document on your laptop and your phone while offline, the two copies diverge. When they reconnect, the software has to merge them. This is a genuinely difficult computer science problem, and most apps dodge it by requiring a central server to be the arbiter.

CRDTs (conflict-free replicated data types) are one solution. They define data structures that can be merged automatically without conflicts. The trade-off is that not every operation maps cleanly to a CRDT, and the implementations are still maturing.

## Why it matters

Cloud dependency is a single point of failure, a privacy risk, and a subscription fee. Local-first software eliminates all three. The data you create should survive the company that made the tool.

## Further reading

- [Local-first software](https://www.inkandswitch.com/local-first/)
