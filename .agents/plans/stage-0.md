# Stage 0 plan — Package identity

Scratch plan; the roadmap is authoritative.

1. DESCRIPTION: real Title, Description, Authors@R (aut, cre, cph),
   Depends R (>= 4.1), Language en-GB, URL, BugReports.
2. .Rbuildignore: confirm the CLAUDE.md "Working with skills" entries.
3. R-CMD-check caller: add the default runners plus Windows R-devel.
4. coverage caller: pin to the v1.23.0 commit with the tag in a comment.
5. CLAUDE.md: Current state.
6. Local: document(), test(), check() clean.
7. PR, quick profile; time every check (< 5 min).
