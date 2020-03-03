---
title: New Subscription Request
date: {{ date | date('dddd, MMMM Do') }}
labels: new-subscription, {{ payload.sender.login }}
requested_by: {{ payload.sender.login }}
---
Issue