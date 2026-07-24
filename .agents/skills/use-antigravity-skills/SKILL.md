---
name: use-antigravity-skills
description: Instructs the agent to ALWAYS check the global skills library (~/.gemini/antigravity/skills/skills/) before responding to any technical prompt.
---

# Global Skills Library Usage

You MUST always check and use relevant skills from the global library located at `~/.gemini/antigravity/skills/skills/` before responding to any prompt related to coding, debugging, reviewing, or deployment.

## Mandatory Steps

1. Before performing any technical task, scan the directory `~/.gemini/antigravity/skills/skills/`.
2. Look for directory names that match the nature of the user's request.
3. Read the `SKILL.md` file within the chosen skill directory.
4. Apply the instructions and patterns found in that skill to your response/implementation.

## Common Request Mapping

| Request Type               | Potential Skill Names                                                                          |
| :------------------------- | :--------------------------------------------------------------------------------------------- |
| **Ruby/Rails Development** | `ruby-pro`, `skill-rails-upgrade`, `tdd-workflows-*`                                           |
| **Frontend/UI/UX**         | `ui-ux-pro-max`, `vanilla-css-mastery`, `frontend-design`, `tailwind-patterns`                 |
| **Security/Debugging**     | `debugger`, `debugging-strategies`, `security-auditor`, `find-bugs`, `top-web-vulnerabilities` |
| **API Design**             | `api-patterns`, `api-design-principles`, `graphql-architect`                                   |
| **Automation/Scripting**   | `bash-pro`, `python-pro`, `workflow-automation`                                                |
| **Testing**                | `testing-patterns`, `tdd-cycle`, `javascript-testing-patterns`                                 |
| **DevOps/Deployment**      | `docker-expert`, `kubernetes-architect`, `terraform-skill`, `deployment-procedures`            |
| **General Architecture**   | `architecture-patterns`, `clean-code`, `solid-principles`                                      |

## Integration Rule

Never answer a technical prompt without first looking up and applying the matching skill(s) from the library.
