POST https://argo.beaver-cloud.ts.net/api/webhook
X-Gitlab-Event: Push Hook
{
  "object_kind": "push",
  "event_name": "push",
  "before": "",
  "after": "",
  "ref": "refs/heads/main",
  "checkout_sha": "",
  "message": null,
  "user_id": 1,
  "user_name": "name",
  "user_username": "username",
  "user_email": "",
  "user_avatar": "",
  "project_id": 1,
  "project": {
    "id": 1,
    "name": "project",
    "description": "",
    "web_url": "https://gitlab.com/kevindurb/infra",
    "avatar_url": null,
    "git_ssh_url": "ssh://git@gitlab.com/kevindurb/infra.git",
    "git_http_url": "https://gitlab.com/kevindurb/infra.git",
    "namespace": "kevindurb",
    "visibility_level": 1,
    "path_with_namespace": "kevindurb/infra",
    "default_branch": "main",
    "ci_config_path": null,
    "homepage": "https://gitlab.com/kevindurb/infra",
    "url": "ssh://git@gitlab.com/kevindurb/infra.git",
    "ssh_url": "ssh://git@gitlab.com/kevindurb/infra.git",
    "http_url": "https://gitlab.com/kevindurb/infra.git"
  },
  "commits": [],
  "total_commits_count": 0,
  "push_options": {},
  "repository": {
    "name": "infra",
    "url": "ssh://git@gitlab.com/kevindurb/infra.git",
    "description": "",
    "homepage": "https://gitlab.com/kevindurb/infra",
    "git_http_url": "https://gitlab.com/kevindurb/infra.git",
    "git_ssh_url": "ssh://git@gitlab.com/kevindurb/infra.git",
    "visibility_level": 10
  }
}
