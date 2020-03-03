---
name: Request New Azure Subscription
about: This automatically requests and provisions a new Azure subscription.
title: 'New Azure Subscription for {{ payload.sender.login }}'
date: {{ date | date('dddd, MMMM Do') }}
labels: new-subscription, {{ payload.sender.login }}
cost-center: ''
---
- [ ] Is this a Sandbox subscription? (You will be given a limit of $500 Azure dollars for experimentation)

Request from: {{ payload.sender.login }}
cost-center: ''

**Is this a sandbox?**

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
