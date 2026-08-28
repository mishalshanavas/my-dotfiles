#!/usr/bin/env bash
# Render the current month as Pango markup with today highlighted.

today=$(date +%-d)

cal | sed -E "3,\$s@(^|[[:space:]])(${today})([[:space:]]|\$)@\\1<span foreground='#60a5fa' weight='600'>\\2</span>\\3@"
