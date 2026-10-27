---
name: seldon-request
description: "Interview the user and draft a valid request to the Witco Platform (Seldon) team as a cincpro/seldon-idp issue that follows the Platform Request issue form, or route a question to seldon-idp Discussions. Use whenever the user wants to ask the platform team for something or file, open, write, or draft a seldon-idp issue or platform request: a new namespace or stack, a PostgreSQL database, Valkey, Memcached, S3, Elasticsearch, AI model or Bedrock access, Terminus (OIDC) client secrets, read access to another team's database, removing or renaming a Seldon app, a change to galactus, the deploy workflows, telemetry, or Kubernetes, or a platform bug report; or when the user asks how to get one of these from the platform team. Not for active incidents (use the incident response process), and not for work the app team does itself, such as deploy.yaml (use galactus) or the deploy workflow (use seldon-deploy)."
---

# seldon-request: draft a Seldon platform request

The Witco Platform team takes requests as issues in `cincpro/seldon-idp`, through the **Platform Request** issue form. This skill interviews the user, fills that form, and creates the issue only after the user approves it. A drafted issue must read the same as one made in the browser.

## Step 1: pick the channel

| The user needs | Channel |
|---|---|
| Something done: a resource, access, a change, a removal, a secret that the platform team enters, or a bug fixed | A **Platform Request** issue. Go on to Step 2. |
| An answer to a question | A post in the **Q&A** category of [Discussions](https://github.com/cincpro/seldon-idp/discussions/new?category=q-a). Draft the post, give the link, and stop. Do not open an issue for a question. |
| Help with an active incident | The [incident response process](https://github.com/cincpro/incident-response). Check [Grafana](https://grafana.witco.net) first. Stop. |
| Work that the app team can do | Do not file a request. Use `galactus`, `seldon-deploy`, or `event-bus`. |

## Step 2: read the current form

The form can change. Read it at the start of each draft:

```bash
gh api repos/cincpro/seldon-idp/contents/.github/ISSUE_TEMPLATE/platform-request.yml \
  -H 'Accept: application/vnd.github.raw'
```

- If it matches [The form](#the-form) below, go on.
- If it differs, use the live form: its labels, its order, its options, and its required fields. Tell the user that the skill's copy is out of date.
- If `gh` cannot read it, use the copy below, and say that you could not check it.

## Step 3: look for a duplicate

```bash
gh issue list -R cincpro/seldon-idp --state open --search "<keywords>"
```

If an open issue covers the request, show it. Suggest a comment on that issue instead of a new one.

## Step 4: interview the user

1. Fill what you already know. Read `deploy.yaml` for the namespace, the app name, and the targets. Use the repo name, the conversation, and the error output. Do not ask for these again; show them for confirmation instead.
2. Ask for the rest in one message, not one question at a time. [references/interviews.md](references/interviews.md) lists what each request type needs.
3. Always ask for the **target date** and the **stakeholder**. Never make them up.
4. If the user does not know an answer, write that into the description. The platform team can ask.
5. If one conversation needs two unrelated things, draft two issues.

## Step 5: draft the issue

### The form

This copy is from 2026-10-15.

| Field (heading) | Required | Value |
|---|---|---|
| Title | yes | `[Request]: <short summary>` |
| `Request Type` | yes | One of: `New service or capability`, `Change to existing service`, `Bug or incident report`, `Access request` |
| `Platform Area` | yes | One of: `Deploying a Namespace or Application`, `Kubernetes Compute`, `AWS Compute (Beanstalk / ECS / Lambda)`, `Datastores (PostgreSQL)`, `Telemetry & Observability`, `Identity & Authentication`, `AI Model Serving`, `Tooling`, `Witco API`, `Other / Not sure` |
| `Namespace` | no | The Seldon namespace, such as `sites-witco`. Not the stack (`dev-sites-witco`), and not the app name. |
| `Description` | yes | What is needed, and the current state. For a change: the current and the desired behavior. For a bug: the current behavior, the steps to reproduce it, and the desired behavior. |
| `Target Date` | yes | `YYYY-MM-DD` |
| `Relevant Links and References` | no | Slack threads, pull requests, workflow runs, Grafana links, related issues |
| `Requested By` | no | The team, the person, or both. There is no standard format. |

### The body

Write one `###` heading for each field, in the order of the form, with the value under it. Write `_No response_` for an empty optional field. Use this structure and nothing else:

```markdown
### Request Type

New service or capability

### Platform Area

Datastores (PostgreSQL)

### Namespace

crm-cinc

### Description

<what is needed, and the current state>

### Target Date

2026-10-31

### Relevant Links and References

_No response_

### Requested By

CRM team
```

### Check the draft

- [ ] The title starts with `[Request]: `.
- [ ] Each dropdown value is an option exactly as the form spells it. When no option fits, it is `Other / Not sure`.
- [ ] The headings match the form's labels, in the form's order, with no extra headings.
- [ ] Each required field has a value. Each empty optional field has `_No response_`.
- [ ] `Namespace` is `{subsystem}-{tenant}`, not a stack or an app name.
- [ ] `Target Date` is `YYYY-MM-DD` and came from the user.
- [ ] The description has everything from [references/interviews.md](references/interviews.md) for this request type.
- [ ] The issue has no secret, no password, no token, and no key. Secrets go only through Vault.
- [ ] The issue has no line that says that an agent drafted it.
- [ ] There are no labels and no assignees. The form sets none.

## Step 6: create the issue

1. Write the body to a file in the scratchpad.
2. Show the title and the body to the user.
3. Give the command. Run it only after the user approves this issue:

   ```bash
   gh issue create -R cincpro/seldon-idp --title "[Request]: <summary>" --body-file <file>
   ```

4. Give the user the issue link.

`gh issue create --template` does not work with an issue form, so always pass the body. If the user prefers the browser, give them the body to paste into [the form](https://github.com/cincpro/seldon-idp/issues/new?template=platform-request.yml).

## References

- [references/interviews.md](references/interviews.md) — what to ask for each kind of request, and the dropdown values to use.
